# app/controllers/pdp/webhooks_controller.rb
module Pdp
  class WebhooksController < ApplicationController
    # Webhook externe => pas d'auth user, pas de CSRF
    skip_before_action :authenticate_user!, raise: false
    protect_from_forgery with: :null_session

    def create
      raw_body = request.raw_post.to_s

      unless valid_signature?(raw_body)
        Rails.logger.warn("[PDP][WEBHOOK] invalid_signature request_id=#{request.request_id}")
        render json: { ok: false, error: "invalid_signature" }, status: :unauthorized
        return
      end

      payload =
        begin
          JSON.parse(raw_body)
        rescue JSON::ParserError
          Rails.logger.warn("[PDP][WEBHOOK] invalid_json request_id=#{request.request_id}")
          render json: { ok: false, error: "invalid_json" }, status: :bad_request
          return
        end

      result = Pdp::WebhookHandler.new(payload: payload).call

      if result[:ok]
        render json: { ok: true }, status: :ok
      else
        # ✅ Important: certaines plateformes retentent si != 2xx.
        # On reste 200 pour éviter spam/retry infini, mais on log l'erreur.
        Rails.logger.warn("[PDP][WEBHOOK] handler_error=#{result[:error]} request_id=#{request.request_id}")
        render json: { ok: true }, status: :ok
      end
    rescue => e
      Rails.logger.error("[PDP][WEBHOOK] error=#{e.class} message=#{e.message} request_id=#{request.request_id}")
      render json: { ok: false, error: "server_error" }, status: :internal_server_error
    end

    private

    def valid_signature?(raw_body)
      secret = ENV["PDP_WEBHOOK_SECRET"].to_s

      # ✅ En prod: secret obligatoire (évite d’oublier)
      if Rails.env.production? && secret.blank?
        Rails.logger.error("[PDP][WEBHOOK] missing PDP_WEBHOOK_SECRET in production")
        return false
      end

      # En dev/test tu peux laisser vide
      return true if secret.blank?

      header_name = ENV.fetch("PDP_WEBHOOK_SIGNATURE_HEADER", "X-Pdp-Signature")
      provided = request.headers[header_name].to_s.strip
      return false if provided.blank?

      # Support formats:
      # - "<hex>"
      # - "sha256=<hex>"
      provided = provided.split("=").last if provided.include?("=")

      computed = OpenSSL::HMAC.hexdigest("SHA256", secret, raw_body)

      # Comparaison safe (anti timing attack)
      return false if computed.blank? || provided.blank?
      ActiveSupport::SecurityUtils.secure_compare(computed, provided)
    end
  end
end

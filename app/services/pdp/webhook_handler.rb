# app/services/pdp/webhook_handler.rb
module Pdp
  class WebhookHandler
    def initialize(payload:)
      @payload = payload
    end

    def call
      # On accepte plusieurs formats possibles (car chaque PDP varie)
      external_id = extract_external_id(@payload)
      status      = extract_status(@payload)

      if external_id.blank?
        return { ok: false, error: "missing_external_id" }
      end

      if status.blank?
        return { ok: false, error: "missing_status" }
      end

      invoice = Invoice.find_by(pdp_external_id: external_id)

      unless invoice
        Rails.logger.warn("[PDP][WEBHOOK] invoice introuvable external_id=#{external_id}")
        return { ok: false, error: "invoice_not_found" }
      end

      mapped = map_status(status)

      unless mapped
        Rails.logger.warn("[PDP][WEBHOOK] status inconnu status=#{status} external_id=#{external_id}")
        return { ok: false, error: "unknown_status" }
      end

      # On stocke aussi le payload brut dans pdp_errors si rejet (utile support)
      if mapped == "rejected"
        invoice.update_columns(
          pdp_status: mapped,
          pdp_errors: @payload.to_json,
          updated_at: Time.current
        )
      else
        invoice.update_columns(
          pdp_status: mapped,
          pdp_errors: nil,
          updated_at: Time.current
        )
      end

      { ok: true }
    rescue => e
      Rails.logger.error("[PDP][WEBHOOK] error=#{e.class} message=#{e.message}")
      { ok: false, error: "handler_error" }
    end

    private

    def extract_external_id(payload)
      payload["external_id"] ||
        payload["id"] ||
        payload.dig("data", "external_id") ||
        payload.dig("data", "id") ||
        payload.dig("invoice", "external_id") ||
        payload.dig("invoice", "id")
    end

    def extract_status(payload)
      payload["status"] ||
        payload.dig("data", "status") ||
        payload.dig("invoice", "status") ||
        payload.dig("event", "status")
    end

    # Mapping interne de ton app
    # - submitted : envoyé (ce que tu fais déjà)
    # - sent      : transmis / en traitement (selon PDP)
    # - accepted  : accepté / validé
    # - rejected  : rejeté
    def map_status(status)
      s = status.to_s.downcase

      return "submitted" if %w[submitted received].include?(s)
      return "sent"      if %w[sent processing in_progress transmitted].include?(s)
      return "accepted"  if %w[accepted validated ok].include?(s)
      return "rejected"  if %w[rejected refused ko error failed].include?(s)

      nil
    end
  end
end

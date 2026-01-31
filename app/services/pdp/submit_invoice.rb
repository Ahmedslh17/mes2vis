# app/services/pdp/submit_invoice.rb
module Pdp
  class SubmitInvoice
    Result = Struct.new(:ok?, :external_id, :errors, keyword_init: true)

    def initialize(invoice:)
      @invoice = invoice
      @company = invoice.company
    end

    def call
      unless @invoice.respond_to?(:ready_for_pdp?) && @invoice.ready_for_pdp?
        return Result.new(ok?: false, external_id: nil, errors: ["Facture pas prête pour e-facture."])
      end

      mode = ENV.fetch("PDP_MODE", "test")

      case mode
      when "test"
        submit_test_mode
      when "api"
        submit_api_mode
      else
        Result.new(ok?: false, external_id: nil, errors: ["PDP_MODE invalide : #{mode.inspect}"])
      end
    end

    private

    # ==========================
    # MODE TEST (inchangé)
    # ==========================
    def submit_test_mode
      fake_external_id = "TEST-PDP-#{SecureRandom.hex(6).upcase}"
      Result.new(ok?: true, external_id: fake_external_id, errors: [])
    end

    # ==========================
    # MODE API (SaaS READY)
    # ==========================
    def submit_api_mode
      provider = @company.respond_to?(:pdp_provider) ? @company.pdp_provider : ENV.fetch("PDP_PROVIDER", "generic")

      # Base URL / API KEY globales (plan gratuit)
      base_url = ENV["PDP_API_BASE_URL"].to_s
      api_key  = ENV["PDP_API_KEY"].to_s

      # Override si entreprise a sa propre clé (plan pro)
      if @company.respond_to?(:pdp_api_key) && @company.pdp_api_key.present?
        api_key = @company.pdp_api_key
      end

      if base_url.blank?
        return Result.new(ok?: false, external_id: nil, errors: ["PDP_API_BASE_URL manquant"])
      end

      client = Pdp::HttpClient.new(
        base_url: base_url,
        api_key: api_key,
        timeout: 20
      )

      adapter =
        case provider.to_s
        when "sage"
          Pdp::Providers::Generic.new(client: client)
        when "pennylane"
          Pdp::Providers::Pennylane.new(client: client, company: @company) # ✅ seule modif
        when "tiime"
          Pdp::Providers::Generic.new(client: client)
        when "generic"
          Pdp::Providers::Generic.new(client: client)
        else
          return Result.new(ok?: false, external_id: nil, errors: ["PDP_PROVIDER inconnu : #{provider.inspect}"])
        end

      data = adapter.submit_invoice(invoice: @invoice)

      if data[:external_id].present?
        Result.new(ok?: true, external_id: data[:external_id], errors: [])
      else
        Result.new(ok?: false, external_id: nil, errors: ["Réponse PDP sans external_id", data[:raw].to_s])
      end
    rescue Pdp::HttpClient::HttpError => e
      Result.new(
        ok?: false,
        external_id: nil,
        errors: ["Erreur PDP HTTP", "status=#{e.status}", e.body.to_s]
      )
    rescue => e
      Result.new(ok?: false, external_id: nil, errors: ["Erreur PDP", e.message])
    end
  end
end

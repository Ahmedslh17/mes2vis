# app/services/pdp/providers/pennylane.rb
module Pdp
  module Providers
    class Pennylane
      def initialize(client:, company:)
        @client  = client
        @company = company
      end

      # Retour attendu : { external_id: "...", raw: {...} }
      def submit_invoice(invoice:)
        payload = build_payload(invoice)

        # ✅ Endpoint configurable (évite de casser quand Pennylane te donne l’URL exacte)
        path = ENV.fetch("PDP_PENNYLANE_SUBMIT_PATH", "/api/v1/pdp/invoices")

        res = @client.post(path, json: payload)

        body = res[:body]

        external_id =
          body["id"] ||
          body["external_id"] ||
          body.dig("data", "id") ||
          body.dig("data", "external_id") ||
          body.dig("invoice", "id") ||
          body.dig("invoice", "external_id")

        { external_id: external_id, raw: body }
      end

      private

      def build_payload(invoice)
        client = invoice.client

        {
          transmission: {
            format: ENV.fetch("PDP_PENNYLANE_FORMAT", "facturx"), # Factur-X
            mode:   ENV.fetch("PDP_PENNYLANE_TRANSMISSION_MODE", "production") # "sandbox" possible selon PDP
          },

          seller: {
            name: @company.name,
            siren: @company.siren,
            vat_number: @company.vat_number,
            email: @company.email,
            address: {
              street:  @company.address,
              zip:     @company.zip_code,
              city:    @company.city,
              country: (@company.country.presence || "FR")
            }
          },

          buyer: {
            name: client&.name,
            siren: client&.siren,
            vat_number: client&.vat_number,
            email: client&.email,
            address: {
              street:  client&.address,
              zip:     client&.zip_code,
              city:    client&.city,
              country: (client&.country.presence || "FR")
            }
          },

          invoice: {
            number: invoice.number,
            issue_date: invoice.issue_date&.to_s,
            due_date: invoice.due_date&.to_s,
            currency: invoice.currency || "EUR",
            operation_category: invoice.operation_category || "services",
            delivery_address: invoice.delivery_address,

            totals: {
              subtotal_cents: invoice.subtotal_cents.to_i,
              vat_cents:      invoice.vat_amount_cents.to_i,
              total_cents:    invoice.total_cents.to_i
            },

            lines: invoice.invoice_items.map do |it|
              {
                description:      it.description,
                quantity:         it.quantity.to_f,
                unit_price_cents: it.unit_price_cents.to_i,
                vat_rate:         it.vat_rate.to_f,
                line_total_cents: it.line_total_cents.to_i
              }
            end
          }
        }
      end
    end
  end
end

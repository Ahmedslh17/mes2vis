# app/services/pdp/providers/generic.rb
module Pdp
  module Providers
    class Generic
      def initialize(client:)
        @client = client
      end

      # Retour attendu : { external_id: "...", raw: {...} }
      def submit_invoice(invoice:)
        payload = build_payload(invoice)

        # ⚠️ Ici "endpoint" est générique.
        # Quand on choisira ta PDP, on mettra le vrai path + champs exacts.
        res = @client.post("/invoices", json: payload)

        external_id =
          res.dig(:body, "id") ||
          res.dig(:body, "external_id") ||
          res.dig(:body, "data", "id")

        { external_id: external_id, raw: res[:body] }
      end

      private

      def build_payload(invoice)
        {
          invoice: {
            number: invoice.number,
            issue_date: invoice.issue_date&.to_s,
            due_date: invoice.due_date&.to_s,
            currency: invoice.currency || "EUR",
            totals: {
              subtotal_cents: invoice.subtotal_cents.to_i,
              vat_cents: invoice.vat_amount_cents.to_i,
              total_cents: invoice.total_cents.to_i
            },
            seller: {
              name: invoice.company&.name,
              siren: invoice.company&.siren,
              vat_number: invoice.company&.vat_number,
              email: invoice.company&.email
            },
            buyer: {
              name: invoice.client&.name,
              siren: invoice.client&.siren,
              vat_number: invoice.client&.vat_number,
              email: invoice.client&.email
            },
            lines: invoice.invoice_items.map do |it|
              {
                description: it.description,
                quantity: it.quantity.to_f,
                unit_price_cents: it.unit_price_cents.to_i,
                vat_rate: it.vat_rate.to_f,
                line_total_cents: it.line_total_cents.to_i
              }
            end
          }
        }
      end
    end
  end
end

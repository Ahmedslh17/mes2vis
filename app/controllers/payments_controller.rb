class PaymentsController < ApplicationController
  before_action :authenticate_user!

  def create
    @company = current_user.company
    @invoice = @company.invoices.find(params[:id])

    if @invoice.total_cents.to_i <= 0
      redirect_to invoice_path(@invoice),
                  alert: "Le montant de la facture doit être supérieur à 0€ pour un paiement en ligne."
      return
    end

    if @invoice.client.email.blank?
      redirect_to invoice_path(@invoice),
                  alert: "Le client doit avoir un email pour lancer le paiement en ligne."
      return
    end

    session = Stripe::Checkout::Session.create(
      mode: "payment",
      success_url: invoice_url(@invoice, paid: true),
      cancel_url: invoice_url(@invoice),
      customer_email: @invoice.client.email,
      line_items: [
        {
          quantity: 1,
          price_data: {
            currency: "eur",
            unit_amount: @invoice.total_cents.to_i,
            product_data: {
              name: "Facture #{@invoice.number || @invoice.id}",
              description: @company.name
            }
          }
        }
      ],
      metadata: {
        invoice_id: @invoice.id,
        company_id: @company.id
      }
    )

    redirect_to session.url, allow_other_host: true, status: 303
  rescue => e
    Rails.logger.error("Stripe checkout error: #{e.message}")
    redirect_to invoice_path(@invoice),
                alert: "Impossible de démarrer le paiement en ligne pour le moment."
  end
end

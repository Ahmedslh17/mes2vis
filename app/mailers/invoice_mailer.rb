class InvoiceMailer < ApplicationMailer
  # Tous les mails de ce mailer utiliseront cet expéditeur
  default from: 'Mes2Vis <notifications@mes2vis.com>'

  def send_invoice(invoice)
    @invoice = invoice
    @company = invoice.company
    @client  = invoice.client

    attachments["facture-#{invoice.number || invoice.id}.pdf"] =
      InvoicePdf.new(invoice).render

    mail(
      to: @client.email,
      subject: "Votre facture #{invoice.number || invoice.id}"
    )
  end

  def reminder_invoice(invoice)
    @invoice = invoice
    @company = invoice.company
    @client  = invoice.client

    attachments["facture-#{invoice.number || invoice.id}.pdf"] =
      InvoicePdf.new(invoice).render

    mail(
      to: @client.email,
      subject: "Rappel - Facture #{@invoice.number || @invoice.id} en attente de paiement"
    )
  end
end

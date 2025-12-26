# app/pdfs/invoice_pdf.rb
require "stringio"
require "prawn"
require "prawn/table"

class InvoicePdf
  def initialize(invoice)
    @invoice = invoice
    @company = invoice.company
    @client  = invoice.client
  end

  def render
    Prawn::Document.new(page_size: "A4", margin: 40) do |pdf|
      # Police (fallback si Inter absente)
      pdf.font "Helvetica"

      build_header(pdf)
      pdf.move_down 20
      build_company_and_client_blocks(pdf)
      pdf.move_down 25
      build_items_table(pdf)
      pdf.move_down 20
      build_totals(pdf)
      pdf.move_down 20
      build_footer(pdf)
    end.render
  end

  private

  ###############################################
  # HEADER avec LOGO entreprise
  ###############################################
  def build_header(pdf)
    pdf.font_size 20

    pdf.bounding_box([0, pdf.cursor], width: pdf.bounds.width, height: 50) do

      # === LOGO À GAUCHE === //
      pdf.bounding_box([0, pdf.cursor + 50], width: 140, height: 40) do
        if @company&.logo&.attached?
          begin
            pdf.image StringIO.new(@company.logo.download), fit: [120, 40]
          rescue
            draw_default_logo(pdf)
          end
        else
          draw_default_logo(pdf)
        end
      end

      # === TITRE FACTURE À DROITE === //
      pdf.bounding_box([150, pdf.cursor + 50], width: pdf.bounds.width - 150, height: 40) do
        pdf.text "Facture", size: 18, style: :bold, align: :right
        number = @invoice.number.presence || "Facture ##{@invoice.id}"
        pdf.text number.to_s, size: 10, align: :right, color: "6B7280"
      end
    end
  end

  # Logo par défaut ("m2" violet)
  def draw_default_logo(pdf)
    pdf.fill_color "4F46E5"
    pdf.fill_rectangle [pdf.bounds.left, pdf.bounds.top], pdf.bounds.width, pdf.bounds.height

    pdf.fill_color "FFFFFF"
    pdf.text_box "m2",
                 at: [pdf.bounds.left, pdf.bounds.top],
                 width: pdf.bounds.width,
                 height: pdf.bounds.height,
                 align: :center,
                 valign: :center,
                 style: :bold,
                 size: 16

    pdf.fill_color "000000"
  end

  ###############################################
  # SECTION ENTREPRISE / CLIENT
  ###############################################
  def build_company_and_client_blocks(pdf)
    pdf.font_size 10

    # Bloc entreprise
    pdf.bounding_box([0, pdf.cursor], width: pdf.bounds.width / 2 - 10) do
      pdf.text @company.name.to_s, style: :bold, size: 11
      pdf.move_down 4

      pdf.text @company.address.to_s if @company.address.present?

      city_line = [@company.zip_code, @company.city].compact.join(" ")
      pdf.text city_line unless city_line.empty?

      pdf.text @company.country.to_s if @company.country.present?

      pdf.move_down 4
      pdf.text "SIREN : #{@company.siren}", size: 9 if @company.siren.present?
      pdf.text "TVA : #{@company.vat_number}", size: 9 if @company.vat_number.present?

      if @company.email.present? || @company.phone.present?
        pdf.move_down 4
        pdf.text @company.email.to_s if @company.email.present?
        pdf.text @company.phone.to_s if @company.phone.present?
      end
    end

    # Bloc client
    pdf.bounding_box([pdf.bounds.width / 2 + 10, pdf.cursor + 80], width: pdf.bounds.width / 2 - 10) do
      pdf.text "Facturé à", style: :bold, size: 11
      pdf.move_down 4

      pdf.text @client.name.to_s, style: :bold

      if @client.address.present?
        pdf.text @client.address.to_s
        city_line = [@client.zip_code, @client.city].compact.join(" ")
        pdf.text city_line unless city_line.empty?
      end

      pdf.move_down 4
      pdf.text "Email : #{@client.email}", size: 9 if @client.email.present?
      pdf.text "Téléphone : #{@client.phone}", size: 9 if @client.phone.present?

      pdf.move_down 8
      issue = @invoice.issue_date&.strftime("%d/%m/%Y")
      due   = @invoice.due_date&.strftime("%d/%m/%Y")

      pdf.text "Date d’émission : #{issue}", size: 9 if issue
      pdf.text "Date d’échéance : #{due}", size: 9 if due
      pdf.text "Statut : #{human_status(@invoice.status)}", size: 9
    end
  end

  ###############################################
  # ITEMS TABLE
  ###############################################
  def build_items_table(pdf)
    pdf.font_size 9

    headers = ["Description", "Quantité", "PU HT", "TVA", "Total HT"]

    data = @invoice.invoice_items.map do |item|
      [
        item.description.presence || "-",
        sprintf("%.2f", item.quantity.to_f),
        format_eur(item.unit_price_cents / 100.0),
        "#{item.vat_rate.to_i} %",
        format_eur(item.line_total_cents / 100.0)
      ]
    end

    pdf.table([headers] + data, header: true, width: pdf.bounds.width) do |t|
      t.row(0).font_style = :bold
      t.row(0).background_color = "F3F4F6"
      t.row(0).text_color = "4B5563"

      t.cells.padding = 6
      t.rows(1..-1).border_color = "E5E7EB"
    end
  end

  ###############################################
  # TOTALS
  ###############################################
  def build_totals(pdf)
    subtotal = @invoice.subtotal_cents / 100.0
    vat      = @invoice.vat_amount_cents / 100.0
    total    = @invoice.total_cents / 100.0

    pdf.bounding_box([pdf.bounds.width / 2, pdf.cursor], width: pdf.bounds.width / 2) do
      pdf.table(
        [
          ["Sous-total HT", format_eur(subtotal)],
          ["TVA",           format_eur(vat)],
          ["Total TTC",     format_eur(total)]
        ],
        width: pdf.bounds.width
      ) do |t|
        t.columns(0).align = :right
        t.columns(1).align = :right
        t.row(2).font_style = :bold
        t.row(2).size = 11
      end
    end
  end

  ###############################################
  # FOOTER
  ###############################################
  def build_footer(pdf)
    notes = @invoice.notes.to_s.strip
    instructions = @company.payment_instructions.to_s.strip

    has_bank = instructions.present? || @company.iban.present? || @company.bic.present?

    if notes.present? || has_bank
      pdf.stroke_color "E5E7EB"
      pdf.stroke_horizontal_rule
      pdf.move_down 8
    end

    if notes.present?
      pdf.text "Conditions de paiement", style: :bold, size: 9
      pdf.text notes, size: 9
      pdf.move_down 8
    end

    if has_bank
      pdf.text "Informations bancaires", style: :bold, size: 9
      pdf.text instructions, size: 9 if instructions.present?
      pdf.text "IBAN : #{@company.iban}", size: 9 if @company.iban.present?
      pdf.text "BIC : #{@company.bic}", size: 9 if @company.bic.present?
    end

    pdf.move_down 12
    pdf.font_size 8
    pdf.fill_color "9CA3AF"
    pdf.text "Facture générée avec mes2vis.", align: :center
    pdf.fill_color "000000"
  end

  ###############################################
  # HELPERS
  ###############################################
  def format_eur(amount)
    parts = sprintf("%.2f", amount).split(".")
    integer = parts[0].reverse.scan(/.{1,3}/).join(" ").reverse
    "#{integer},#{parts[1]} €"
  end

  def human_status(status)
    {
      "paid" => "Payée",
      "pending" => "En attente",
      "overdue" => "En retard"
    }[status] || "Brouillon"
  end
end

class InvoicesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_subscription_for_second_invoice!, only: [:new, :create, :duplicate]
  before_action :set_company
  before_action :set_invoice, only: [
    :show,
    :edit,
    :update,
    :destroy,
    :send_email,
    :update_status,
    :duplicate,
    :send_reminder
  ]

  # === INDEX : liste + recherche + filtres ===
  def index
    scope = @company.invoices.includes(:client)

    # Recherche (numéro ou nom client)
    if params[:query].present?
      q = "%#{params[:query]}%"
      scope = scope.joins(:client).where(
        "invoices.number ILIKE :q OR clients.name ILIKE :q",
        q: q
      )
    end

    # Filtre par statut
    if params[:status].present?
      scope = scope.where(status: params[:status])
    end

    # Filtre par client
    if params[:client_id].present?
      scope = scope.where(client_id: params[:client_id])
    end

    @invoices = scope.order(issue_date: :desc)

    # Pour garder les valeurs dans le formulaire
    @query              = params[:query]
    @status             = params[:status]
    @selected_client_id = params[:client_id]
  end

  # === SHOW ===
  def show
    # Message spécial quand on revient de Stripe
    if params[:paid] == "true"
      flash.now[:notice] = "Si le paiement Stripe est validé, la facture passera en « payée » automatiquement."
    end

    respond_to do |format|
      format.html
      format.pdf do
        pdf = InvoicePdf.new(@invoice)
        filename = "facture-#{@invoice.number.presence || @invoice.id}.pdf"
        send_data pdf.render,
                  filename: filename,
                  type: "application/pdf",
                  disposition: "inline"
      end
    end
  end

  # === NEW ===
  def new
    # client préselectionné éventuellement
    preselected_client_id = params.dig(:invoice, :client_id)

    @invoice = @company.invoices.new(
      issue_date: Date.today,
      due_date:   Date.today + 30,
      currency:   "EUR",
      client_id:  preselected_client_id
    )

    @clients = @company.clients

    # au moins une ligne vide
    @invoice.invoice_items.build
  end

  # === CREATE ===
  def create
    @invoice = @company.invoices.new(invoice_params)
    @invoice.currency ||= "EUR"

    ensure_paid_at_if_paid(@invoice)
    compute_totals_from_items(@invoice)

    if @invoice.save
      redirect_to invoices_path, notice: "Facture créée avec succès."
    else
      @clients = @company.clients
      flash.now[:alert] = "Erreur lors de la création de la facture."
      render :new, status: :unprocessable_entity
    end
  end

  # === EDIT ===
  def edit
    @clients = @company.clients
    @invoice.invoice_items.build if @invoice.invoice_items.empty?
  end

  # === UPDATE ===
  def update
    @company = current_user.company
    @invoice = @company.invoices.includes(:invoice_items).find(params[:id])

    @invoice.assign_attributes(invoice_params)
    @invoice.currency ||= "EUR"

    ensure_paid_at_if_paid(@invoice)
    compute_totals_from_items(@invoice)

    if @invoice.save
      redirect_to invoice_path(@invoice), notice: "Facture mise à jour avec succès."
    else
      @clients = @company.clients
      flash.now[:alert] = "Erreur lors de la mise à jour de la facture."
      render :edit, status: :unprocessable_entity
    end
  end

  # === ENVOI PAR EMAIL ===
  def send_email
    if @invoice.client.email.blank?
      redirect_to invoice_path(@invoice),
                  alert: "Ce client n'a pas d'email. Ajoute un email sur sa fiche client."
      return
    end

    begin
      InvoiceMailer.send_invoice(@invoice).deliver_now
      redirect_to invoice_path(@invoice),
                  notice: "Facture envoyée par email (prévisualisation ouverte en développement)."
    rescue => e
      Rails.logger.error("Erreur envoi facture ##{@invoice.id} : #{e.message}")
      redirect_to invoice_path(@invoice),
                  alert: "Impossible d'envoyer l'email pour le moment."
    end
  end

  # === RAPPEL DE PAIEMENT ===
  def send_reminder
    # @company et @invoice déjà chargés par les before_action

    if @invoice.client.email.blank?
      redirect_to invoice_path(@invoice),
                  alert: "Ce client n'a pas d'email. Ajoute un email sur sa fiche client."
      return
    end

    unless @invoice.status == "overdue"
      redirect_to invoice_path(@invoice),
                  alert: "Tu peux envoyer un rappel uniquement pour une facture en retard."
      return
    end

    if @invoice.last_reminder_sent_at.present? && @invoice.last_reminder_sent_at > 24.hours.ago
      redirect_to invoice_path(@invoice),
                  alert: "Un rappel a déjà été envoyé il y a moins de 24h."
      return
    end

    begin
      InvoiceMailer.reminder_invoice(@invoice).deliver_now
      @invoice.update(last_reminder_sent_at: Time.current)
      redirect_to invoice_path(@invoice), notice: "Rappel envoyé au client."
    rescue => e
      Rails.logger.error("Erreur envoi rappel facture ##{@invoice.id} : #{e.message}")
      redirect_to invoice_path(@invoice), alert: "Impossible d'envoyer le rappel pour le moment."
    end
  end

  # === DELETE ===
  def destroy
    @invoice.destroy
    redirect_to invoices_path, notice: "Facture supprimée avec succès."
  end

  # === UPDATE STATUT ===
  def update_status
    @company = current_user.company
    @invoice = @company.invoices.find(params[:id])

    if @invoice.update(status: params[:status])
      if @invoice.status == "paid" && @invoice.paid_at.blank?
        @invoice.update(paid_at: Time.current)
      end
      redirect_to invoice_path(@invoice), notice: "Statut mis à jour avec succès."
    else
      redirect_to invoice_path(@invoice), alert: "Erreur lors de la mise à jour du statut."
    end
  end

  # === DUPLIQUER ===
  def duplicate
    invoice = @invoice

    new_invoice = invoice.dup
    new_invoice.number = nil
    new_invoice.status = "pending"

    invoice.invoice_items.each do |item|
      new_invoice.invoice_items.build(
        description:      item.description,
        quantity:         item.quantity,
        unit_price_cents: item.unit_price_cents,
        vat_rate:         item.vat_rate
      )
    end

    compute_totals_from_items(new_invoice)

    if new_invoice.save
      redirect_to edit_invoice_path(new_invoice), notice: "Facture dupliquée avec succès."
    else
      redirect_to invoice_path(invoice), alert: "Erreur lors de la duplication de la facture."
    end
  end

  private

  def set_company
    @company = current_user.company
  end

  def set_invoice
    @invoice = @company.invoices.includes(:client, :invoice_items).find(params[:id])
  end

  def invoice_params
    params.require(:invoice).permit(
      :number,
      :client_id,
      :issue_date,
      :due_date,
      :status,
      :notes,
      :paid_at,
      :payment_method,
      :payment_notes,
      :subtotal_cents,
      :vat_amount_cents,
      invoice_items_attributes: [
        :id,
        :description,
        :quantity,
        :unit_price_cents,
        :unit_price_eur,
        :vat_rate,
        :line_total_cents,
        :_destroy
      ]
    )
  end

  def ensure_paid_at_if_paid(invoice)
    if invoice.status == "paid" && invoice.paid_at.blank?
      invoice.paid_at = Time.current
    end
  end

  def compute_totals_from_items(invoice)
    subtotal_cents = 0
    vat_cents      = 0

    invoice.invoice_items.each do |item|
      # Ligne complètement vide → on la supprime
      if item.description.blank? && item.quantity.blank? && item.unit_price_cents.blank? && item.unit_price_eur.blank?
        item.mark_for_destruction
        next
      end

      # Quantité (par défaut 1)
      qty = item.quantity.present? ? item.quantity.to_f : 1.0

      # Prix unitaire : on passe par unit_price_eur si utilisé
      if item.respond_to?(:unit_price_eur) && item.unit_price_cents.blank?
        # le setter unit_price_eur a déjà rempli unit_price_cents
      end

      # Si pas passé par unit_price_eur, on normalise tout de même
      raw_price =
        if item.unit_price_cents.present?
          item.unit_price_cents.to_s
        else
          "0"
        end

      raw_price = raw_price.to_s.tr(",", ".")
      unit_price_eur   = raw_price.to_f
      unit_price_cents = (unit_price_eur * 100).round
      item.unit_price_cents ||= unit_price_cents

      # Sous-total de la ligne
      line_subtotal = (qty * item.unit_price_cents.to_i).round
      item.line_total_cents = line_subtotal

      subtotal_cents += line_subtotal

      # TVA
      rate = item.vat_rate.present? ? item.vat_rate.to_f : 0.0
      vat_cents += (line_subtotal * rate / 100.0).round
    end

    invoice.subtotal_cents   = subtotal_cents
    invoice.vat_amount_cents = vat_cents
    invoice.total_cents      = subtotal_cents + vat_cents
  end
end

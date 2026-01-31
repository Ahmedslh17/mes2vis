class Invoice < ApplicationRecord
  belongs_to :company
  belongs_to :client
  has_many :invoice_items, dependent: :destroy

  accepts_nested_attributes_for :invoice_items, allow_destroy: true

  # Validations de base
  validates :client, presence: true
  validates :issue_date, presence: true
  validates :due_date, presence: true
  validates :total_cents, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # Numéro unique par entreprise
  validates :number, uniqueness: { scope: :company_id }, allow_nil: true

  # Générer automatiquement le numéro si vide
  before_validation :generate_number, on: :create

  # Valeurs e-facture par défaut
  before_validation :set_efacture_defaults, on: :create

  # Vérif e-facture : si client pro => SIREN obligatoire
  validate :professional_client_must_have_siren

  # ✅ PDP (préparation réforme) : met à jour le statut "pdp_status" automatiquement
  before_validation :sync_pdp_status

  # Petit helper pratique
  def paid?
    status == "paid"
  end

  # ==========================
  # ✅ E-FACTURE / PDP HELPERS
  # ==========================
  def client_is_pro?
    if client.respond_to?(:professionnel?)
      client.professionnel?
    else
      client.respond_to?(:client_type) && client.client_type == "professionnel"
    end
  end

  def ready_for_pdp?
    return false if client.nil?
    return false if issue_date.blank? || due_date.blank?
    return false if invoice_items.empty?
    return false if invoice_items.all? { |it| it.description.blank? && it.quantity.blank? && it.unit_price_cents.blank? }
    return false if client_is_pro? && client.siren.blank?
    true
  end

  def pdp_badge
    case pdp_status
    when "draft"     then ["Brouillon PDP", "bg-slate-100 text-slate-700 ring-slate-200"]
    when "ready"     then ["Prête PDP", "bg-emerald-50 text-emerald-700 ring-emerald-200"]
    when "sent"      then ["Envoyée PDP", "bg-indigo-50 text-indigo-700 ring-indigo-200"]
    when "submitted" then ["Envoyée PDP", "bg-indigo-50 text-indigo-700 ring-indigo-200"] # ✅ compat (ta view / mode test)
    when "accepted"  then ["Acceptée PDP", "bg-emerald-50 text-emerald-700 ring-emerald-200"]
    when "rejected"  then ["Rejetée PDP", "bg-rose-50 text-rose-700 ring-rose-200"]
    when "error"     then ["Erreur PDP", "bg-rose-50 text-rose-700 ring-rose-200"]        # ✅ affichage propre
    else                  ["PDP ?", "bg-slate-100 text-slate-700 ring-slate-200"]
    end
  end

  private

  def sync_pdp_status
    return unless respond_to?(:pdp_status)

    # ✅ Ne jamais écraser un statut final / d'envoi / d'erreur
    return if %w[sent submitted accepted rejected error].include?(pdp_status)

    self.pdp_status = ready_for_pdp? ? "ready" : "draft"
  end

  def set_efacture_defaults
    # Catégorie d’opération : valeur simple par défaut
    self.operation_category ||= "services" if respond_to?(:operation_category)

    # Adresse de livraison : par défaut on prend l’adresse du client
    if respond_to?(:delivery_address) && delivery_address.blank? && client.present?
      line2 = [client.zip_code, client.city].compact.join(" ").presence
      full_address = [client.address, line2, client.country].compact.join("\n")
      self.delivery_address = full_address.presence
    end
  end

  def professional_client_must_have_siren
    return if client.nil?

    if client.respond_to?(:professionnel?) && client.professionnel? && client.siren.blank?
      message = I18n.t(
        "activerecord.errors.models.invoice.attributes.base.professional_client_missing_siren",
        default: "Le client est professionnel : le SIREN est obligatoire."
      )
      errors.add(:base, message)
    end
  end

  def generate_number
    return if number.present?
    return if company.nil?

    date  = issue_date || Date.today
    year  = date.year
    month = format("%02d", date.month)

    pattern = "FAC-#{year}-#{month}-%"

    last_invoice = company.invoices
                          .where("number LIKE ?", pattern)
                          .order(:number)
                          .last

    last_seq =
      if last_invoice&.number.to_s.split("-").last =~ /\A\d+\z/
        last_invoice.number.split("-").last.to_i
      else
        0
      end

    next_seq = last_seq + 1

    self.number = format("FAC-%<year>d-%<month>s-%<seq>04d",
                         year: year,
                         month: month,
                         seq: next_seq)
  end
end

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

  # Petit helper pratique
  def paid?
    status == "paid"
  end

  private

  def generate_number
    # Si un numéro a été saisi manuellement, on ne touche à rien
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

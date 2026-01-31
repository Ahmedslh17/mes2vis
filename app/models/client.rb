class Client < ApplicationRecord
  belongs_to :company
  has_many :invoices, dependent: :destroy

  CLIENT_TYPES = %w[particulier professionnel].freeze

  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :address, presence: true

  validates :client_type, inclusion: { in: CLIENT_TYPES }

  # ✅ SIREN obligatoire uniquement si client pro
  validates :siren,
            presence: { message: "est obligatoire pour un client professionnel" },
            length: { is: 9, message: "doit contenir exactement 9 chiffres" },
            format: { with: /\A\d+\z/, message: "doit contenir uniquement des chiffres" },
            if: :professionnel?

  # ✅ Si on repasse le client en "particulier", on supprime le SIREN automatiquement
  before_validation :clear_siren_unless_professional

  def professionnel?
    client_type == "professionnel"
  end

  private

  def clear_siren_unless_professional
    self.siren = nil unless professionnel?
  end
end

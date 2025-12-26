class Company < ApplicationRecord
  belongs_to :user
  has_many :clients,  dependent: :destroy
  has_many :invoices, dependent: :destroy

  validates :name,    presence: true
  validates :address, presence: true

  validates :siren,
            length: { is: 9 },
            allow_blank: true

  validates :vat_number,
            length: { maximum: 20 },
            allow_blank: true

  validates :iban,
            length: { minimum: 10 },
            allow_blank: true

  validates :bic,
            length: { minimum: 8, maximum: 11 },
            allow_blank: true

  has_one_attached :logo

  attr_accessor :remove_logo

  before_save :purge_logo_if_needed

  private

  def purge_logo_if_needed
    if ActiveModel::Type::Boolean.new.cast(remove_logo) && logo.attached?
      logo.purge
    end
  end
end

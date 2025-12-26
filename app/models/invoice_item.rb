class InvoiceItem < ApplicationRecord
  belongs_to :invoice

  # Champ virtuel : prix en euros
  def unit_price_eur
    return nil if unit_price_cents.nil?
    (unit_price_cents.to_f / 100.0)
  end

  def unit_price_eur=(value)
    if value.present?
      normalized = value.to_s.tr(",", ".").to_f
      self.unit_price_cents = (normalized * 100).round
    else
      self.unit_price_cents = 0
    end
  end
end

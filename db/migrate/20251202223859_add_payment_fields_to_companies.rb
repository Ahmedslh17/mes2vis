class AddPaymentFieldsToCompanies < ActiveRecord::Migration[7.1]
  def change
    add_column :companies, :iban, :string
    add_column :companies, :bic, :string
    add_column :companies, :payment_instructions, :text
  end
end

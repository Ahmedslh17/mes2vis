class AddFieldsToCompanies < ActiveRecord::Migration[7.1]
  def change
    add_column :companies, :legal_name, :string
    add_column :companies, :zip_code, :string
    add_column :companies, :city, :string
    add_column :companies, :country, :string
    add_column :companies, :phone, :string
    add_column :companies, :website, :string
    add_column :companies, :siren, :string
    add_column :companies, :vat_number, :string
  end
end

class CreateClients < ActiveRecord::Migration[7.1]
  def change
    create_table :clients do |t|
      t.string :name
      t.string :contact_name
      t.string :email
      t.string :phone
      t.string :address
      t.string :zip_code
      t.string :city
      t.string :country
      t.string :vat_number
      t.references :company, null: false, foreign_key: true

      t.timestamps
    end
  end
end

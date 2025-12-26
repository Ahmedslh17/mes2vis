class CreateInvoiceItems < ActiveRecord::Migration[7.1]
  def change
    create_table :invoice_items do |t|
      t.string :description
      t.decimal :quantity, precision: 10, scale: 2
      t.integer :unit_price_cents
      t.decimal :vat_rate, precision: 5, scale: 2
      t.integer :line_total_cents
      t.integer :position
      t.references :invoice, null: false, foreign_key: true

      t.timestamps
    end
  end
end

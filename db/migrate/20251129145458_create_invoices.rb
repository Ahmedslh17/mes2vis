class CreateInvoices < ActiveRecord::Migration[7.1]
  def change
    create_table :invoices do |t|
      t.string :number
      t.string :status
      t.date :issue_date
      t.date :due_date
      t.string :currency
      t.integer :subtotal_cents
      t.integer :vat_amount_cents
      t.integer :total_cents
      t.text :notes
      t.references :company, null: false, foreign_key: true
      t.references :client, null: false, foreign_key: true

      t.timestamps
    end
  end
end

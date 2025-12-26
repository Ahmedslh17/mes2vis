class AddPaymentFieldsToInvoices < ActiveRecord::Migration[7.1]
  def change
    add_column :invoices, :paid_at, :datetime
    add_column :invoices, :payment_method, :string
    add_column :invoices, :payment_notes, :text
  end
end

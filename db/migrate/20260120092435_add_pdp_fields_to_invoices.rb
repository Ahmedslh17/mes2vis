class AddPdpFieldsToInvoices < ActiveRecord::Migration[7.1]
  def change
    add_column :invoices, :operation_category, :string
    add_column :invoices, :delivery_address, :text

    add_column :invoices, :pdp_status, :string, default: "draft", null: false
    add_column :invoices, :pdp_external_id, :string
    add_column :invoices, :pdp_errors, :text
  end
end

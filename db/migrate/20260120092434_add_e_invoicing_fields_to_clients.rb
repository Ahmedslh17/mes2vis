class AddEInvoicingFieldsToClients < ActiveRecord::Migration[7.1]
  def change
    add_column :clients, :client_type, :string, default: "particulier", null: false
    add_column :clients, :siren, :string
  end
end

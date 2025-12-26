class AddUniqueIndexToInvoicesNumberPerCompany < ActiveRecord::Migration[7.1]
  def up
    # On remplace les numéros vides par NULL
    # (PostgreSQL autorise plusieurs NULL dans un index unique)
    execute <<-SQL.squish
      UPDATE invoices
      SET number = NULL
      WHERE number IS NULL OR number = '';
    SQL

    add_index :invoices, [:company_id, :number], unique: true
  end

  def down
    remove_index :invoices, column: [:company_id, :number]
  end
end

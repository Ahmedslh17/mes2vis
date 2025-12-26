class SetDefaultSubscriptionCurrencyOnUsers < ActiveRecord::Migration[7.1]
  def up
    # Backfill des valeurs manquantes
    execute <<~SQL
      UPDATE users
      SET subscription_currency = 'EUR'
      WHERE subscription_currency IS NULL OR subscription_currency = '';
    SQL

    # Default DB
    change_column_default :users, :subscription_currency, from: nil, to: "EUR"
  end

  def down
    change_column_default :users, :subscription_currency, from: "EUR", to: nil
  end
end

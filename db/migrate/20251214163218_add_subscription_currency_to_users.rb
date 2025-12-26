class AddSubscriptionCurrencyToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :subscription_currency, :string
  end
end

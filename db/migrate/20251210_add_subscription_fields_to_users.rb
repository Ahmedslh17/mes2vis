class AddSubscriptionFieldsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :stripe_customer_id, :string
    add_column :users, :stripe_subscription_id, :string
    add_column :users, :subscription_status, :string
    add_column :users, :subscription_plan, :string
    add_column :users, :subscription_current_period_end, :datetime
    add_column :users, :grandfathered, :boolean, default: false, null: false
  end
end

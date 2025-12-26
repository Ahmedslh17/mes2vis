class AddLastReminderSentAtToInvoices < ActiveRecord::Migration[7.1]
  def change
    add_column :invoices, :last_reminder_sent_at, :datetime
  end
end

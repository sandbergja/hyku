class AddBatchEmailFrequencyToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :batch_email_frequency, :string, default: 'off' unless column_exists?(:users, :batch_email_frequency)
  end
end

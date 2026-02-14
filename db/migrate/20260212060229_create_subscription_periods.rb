class CreateSubscriptionPeriods < ActiveRecord::Migration[8.1]
  def change
    create_table :subscription_periods do |t|
      t.references :subscription, null: false, foreign_key: true
      t.string :event_type, null: false
      t.decimal :amount, precision: 10, scale: 2
      t.string :currency
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false

      t.timestamps
    end

    add_index :subscription_periods, [:subscription_id, :starts_at]
  end
end

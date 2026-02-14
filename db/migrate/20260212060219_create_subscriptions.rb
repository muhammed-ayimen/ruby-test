class CreateSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :subscriptions do |t|
      t.string :user_id, null: false
      t.string :transaction_id, null: false
      t.string :product_id, null: false
      t.string :status, null: false, default: "provisional"
      t.datetime :current_period_start
      t.datetime :current_period_end
      t.datetime :cancelled_at

      t.timestamps
    end

    add_index :subscriptions, :transaction_id, unique: true
    add_index :subscriptions, :user_id
    add_index :subscriptions, :status
    add_index :subscriptions, [:user_id, :status]
  end
end

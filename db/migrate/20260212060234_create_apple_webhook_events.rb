class CreateAppleWebhookEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :apple_webhook_events do |t|
      t.string :notification_uuid, null: false
      t.string :event_type, null: false
      t.string :transaction_id, null: false
      t.string :product_id
      t.decimal :amount, precision: 10, scale: 2
      t.string :currency
      t.datetime :purchase_date
      t.datetime :expires_date
      t.string :processing_status, null: false, default: "pending"
      t.text :error_message
      t.jsonb :raw_payload

      t.timestamps
    end

    add_index :apple_webhook_events, :notification_uuid, unique: true
    add_index :apple_webhook_events, :transaction_id
    add_index :apple_webhook_events, :processing_status
  end
end

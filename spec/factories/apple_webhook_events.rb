FactoryBot.define do
  factory :apple_webhook_event do
    sequence(:notification_uuid) { |n| "notif_#{n}" }
    event_type { "PURCHASE" }
    sequence(:transaction_id) { |n| "txn_#{n}" }
    product_id { "com.samansa.subscription.monthly" }
    amount { 3.90 }
    currency { "USD" }
    purchase_date { Time.current }
    expires_date { 1.month.from_now }
    processing_status { "pending" }
  end
end

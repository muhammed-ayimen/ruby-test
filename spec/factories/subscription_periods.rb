FactoryBot.define do
  factory :subscription_period do
    subscription
    event_type { "PURCHASE" }
    amount { 3.90 }
    currency { "USD" }
    starts_at { Time.current }
    ends_at { 1.month.from_now }
  end
end

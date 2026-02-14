FactoryBot.define do
  factory :subscription do
    user_id { SecureRandom.uuid }
    sequence(:transaction_id) { |n| "txn_#{n}" }
    product_id { "com.samansa.subscription.monthly" }
    status { "provisional" }

    trait :active do
      status { "active" }
      current_period_start { Time.current }
      current_period_end { 1.month.from_now }
    end

    trait :cancelled do
      status { "cancelled" }
      current_period_start { Time.current }
      current_period_end { 1.month.from_now }
      cancelled_at { Time.current }
    end

    trait :expired do
      status { "expired" }
      current_period_start { 2.months.ago }
      current_period_end { 1.month.ago }
    end
  end
end

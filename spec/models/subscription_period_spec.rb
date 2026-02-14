require "rails_helper"

RSpec.describe SubscriptionPeriod, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:event_type) }
    it { is_expected.to validate_inclusion_of(:event_type).in_array(%w[PURCHASE RENEW]) }
    it { is_expected.to validate_presence_of(:starts_at) }
    it { is_expected.to validate_presence_of(:ends_at) }
    it { is_expected.to validate_numericality_of(:amount).is_greater_than_or_equal_to(0).allow_nil }
  end

  describe "associations" do
    it { is_expected.to belong_to(:subscription) }
  end

  describe "scopes" do
    describe ".chronological" do
      it "orders by starts_at ascending" do
        subscription = create(:subscription, :active)
        later = create(:subscription_period, subscription: subscription, starts_at: 2.days.from_now, ends_at: 1.month.from_now)
        earlier = create(:subscription_period, subscription: subscription, starts_at: 1.day.ago, ends_at: 1.month.from_now)

        expect(SubscriptionPeriod.chronological).to eq([earlier, later])
      end
    end
  end
end

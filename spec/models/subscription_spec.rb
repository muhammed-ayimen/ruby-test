require "rails_helper"

RSpec.describe Subscription, type: :model do
  describe "validations" do
    subject { build(:subscription) }

    it { is_expected.to validate_presence_of(:user_id) }
    it { is_expected.to validate_presence_of(:transaction_id) }
    it { is_expected.to validate_uniqueness_of(:transaction_id) }
    it { is_expected.to validate_presence_of(:product_id) }
    it { is_expected.to validate_presence_of(:status) }
  end

  describe "associations" do
    it { is_expected.to have_many(:subscription_periods).dependent(:destroy) }
  end

  describe "state machine" do
    describe "initial state" do
      it "starts as provisional" do
        expect(build(:subscription).status).to eq("provisional")
      end
    end

    describe "#activate" do
      it "transitions from provisional to active" do
        subscription = create(:subscription)
        subscription.activate!
        expect(subscription.status).to eq("active")
      end

      it "cannot transition from active" do
        subscription = create(:subscription, :active)
        expect { subscription.activate! }.to raise_error(AASM::InvalidTransition)
      end
    end

    describe "#renew" do
      it "transitions from active to active" do
        subscription = create(:subscription, :active)
        subscription.renew!
        expect(subscription.status).to eq("active")
      end

      it "cannot transition from provisional" do
        subscription = create(:subscription)
        expect { subscription.renew! }.to raise_error(AASM::InvalidTransition)
      end
    end

    describe "#cancel" do
      it "transitions from active to cancelled" do
        subscription = create(:subscription, :active)
        subscription.cancel!
        expect(subscription.status).to eq("cancelled")
      end

      it "cannot transition from provisional" do
        subscription = create(:subscription)
        expect { subscription.cancel! }.to raise_error(AASM::InvalidTransition)
      end
    end

    describe "#expire" do
      it "transitions from provisional to expired" do
        subscription = create(:subscription)
        subscription.expire!
        expect(subscription.status).to eq("expired")
      end

      it "transitions from cancelled to expired" do
        subscription = create(:subscription, :cancelled)
        subscription.expire!
        expect(subscription.status).to eq("expired")
      end

      it "cannot transition from active" do
        subscription = create(:subscription, :active)
        expect { subscription.expire! }.to raise_error(AASM::InvalidTransition)
      end
    end
  end

  describe "#watchable?" do
    it "returns true for active subscription with future period end" do
      subscription = build(:subscription, :active)
      expect(subscription.watchable?).to be true
    end

    it "returns true for cancelled subscription with future period end" do
      subscription = build(:subscription, :cancelled)
      expect(subscription.watchable?).to be true
    end

    it "returns false for provisional subscription" do
      subscription = build(:subscription)
      expect(subscription.watchable?).to be false
    end

    it "returns false for expired subscription" do
      subscription = build(:subscription, :expired)
      expect(subscription.watchable?).to be false
    end

    it "returns false for active subscription with past period end" do
      subscription = build(:subscription, :active, current_period_end: 1.day.ago)
      expect(subscription.watchable?).to be false
    end

    it "returns false for cancelled subscription with past period end" do
      subscription = build(:subscription, :cancelled, current_period_end: 1.day.ago)
      expect(subscription.watchable?).to be false
    end
  end

  describe "scopes" do
    describe ".for_user" do
      it "returns subscriptions for the given user" do
        sub = create(:subscription, user_id: "user_1")
        create(:subscription, user_id: "user_2")

        expect(Subscription.for_user("user_1")).to eq([sub])
      end
    end

    describe ".viewable" do
      it "returns active subscriptions with future period end" do
        viewable = create(:subscription, :active)
        create(:subscription) # provisional
        create(:subscription, :expired)

        expect(Subscription.viewable).to eq([viewable])
      end

      it "returns cancelled subscriptions with future period end" do
        cancelled = create(:subscription, :cancelled)
        expect(Subscription.viewable).to include(cancelled)
      end

      it "excludes subscriptions with past period end" do
        create(:subscription, :active, current_period_end: 1.day.ago)
        expect(Subscription.viewable).to be_empty
      end
    end
  end
end

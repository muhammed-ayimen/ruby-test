require "rails_helper"

RSpec.describe Subscriptions::CreateProvisionalService do
  let(:params) do
    {
      user_id: "user_123",
      transaction_id: "txn_abc",
      product_id: "com.samansa.subscription.monthly"
    }
  end

  describe ".call" do
    context "when subscription does not exist" do
      it "creates a new provisional subscription" do
        result = described_class.call(**params)

        expect(result).to be_success
        expect(result.subscription.status).to eq("provisional")
        expect(result.subscription.transaction_id).to eq("txn_abc")
        expect(result.subscription.user_id).to eq("user_123")
        expect(result.subscription.product_id).to eq("com.samansa.subscription.monthly")
      end

      it "persists the subscription" do
        expect { described_class.call(**params) }
          .to change(Subscription, :count).by(1)
      end
    end

    context "when subscription with same transaction_id already exists" do
      let!(:existing) { create(:subscription, transaction_id: "txn_abc") }

      it "returns the existing subscription (idempotent)" do
        result = described_class.call(**params)

        expect(result).to be_success
        expect(result.subscription.id).to eq(existing.id)
      end

      it "does not create a new subscription" do
        expect { described_class.call(**params) }
          .not_to change(Subscription, :count)
      end
    end

    context "with missing required params" do
      it "returns failure when user_id is missing" do
        result = described_class.call(user_id: "", transaction_id: "txn_1", product_id: "plan_1")
        expect(result).not_to be_success
      end
    end
  end
end

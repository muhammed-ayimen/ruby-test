require "rails_helper"

RSpec.describe Webhooks::Apple::ProcessEventService do
  let!(:subscription) { create(:subscription, transaction_id: "txn_100") }

  let(:purchase_params) do
    ActionController::Parameters.new(
      notification_uuid: "notif_001",
      type: "PURCHASE",
      transaction_id: "txn_100",
      product_id: "com.samansa.subscription.monthly",
      amount: "3.9",
      currency: "USD",
      purchase_date: "2025-10-01T12:00:00Z",
      expires_date: "2025-11-01T12:00:00Z"
    ).permit!
  end

  describe ".call" do
    context "with PURCHASE event" do
      it "activates the subscription" do
        result = described_class.call(purchase_params)

        expect(result).to be_success
        expect(subscription.reload.status).to eq("active")
        expect(subscription.current_period_end).to be_present
      end

      it "creates an event record" do
        expect { described_class.call(purchase_params) }
          .to change(AppleWebhookEvent, :count).by(1)
      end

      it "creates a subscription period" do
        expect { described_class.call(purchase_params) }
          .to change(SubscriptionPeriod, :count).by(1)
      end
    end

    context "with RENEW event" do
      before { subscription.update!(status: "active", current_period_start: 1.month.ago, current_period_end: Time.current) }

      let(:renew_params) do
        ActionController::Parameters.new(
          notification_uuid: "notif_002",
          type: "RENEW",
          transaction_id: "txn_100",
          product_id: "com.samansa.subscription.monthly",
          amount: "3.9",
          currency: "USD",
          purchase_date: "2025-11-01T12:00:00Z",
          expires_date: "2025-12-01T12:00:00Z"
        ).permit!
      end

      it "keeps subscription active and updates period" do
        result = described_class.call(renew_params)

        expect(result).to be_success
        subscription.reload
        expect(subscription.status).to eq("active")
        expect(subscription.current_period_start).to eq(Time.parse("2025-11-01T12:00:00Z"))
      end
    end

    context "with CANCEL event" do
      before { subscription.update!(status: "active", current_period_start: Time.current, current_period_end: 1.month.from_now) }

      let(:cancel_params) do
        ActionController::Parameters.new(
          notification_uuid: "notif_003",
          type: "CANCEL",
          transaction_id: "txn_100",
          product_id: "com.samansa.subscription.monthly",
          amount: "3.9",
          currency: "USD",
          purchase_date: "2025-10-01T12:00:00Z",
          expires_date: "2025-11-01T12:00:00Z"
        ).permit!
      end

      it "cancels the subscription" do
        result = described_class.call(cancel_params)

        expect(result).to be_success
        expect(subscription.reload.status).to eq("cancelled")
        expect(subscription.cancelled_at).to be_present
      end
    end

    context "with duplicate notification_uuid (idempotency)" do
      it "returns duplicate result without reprocessing" do
        described_class.call(purchase_params)

        duplicate_params = purchase_params.merge(notification_uuid: "notif_001")
        result = described_class.call(duplicate_params)

        expect(result).to be_duplicate
        expect(AppleWebhookEvent.count).to eq(1)
      end
    end

    context "with unknown event type" do
      let(:unknown_params) do
        ActionController::Parameters.new(
          notification_uuid: "notif_004",
          type: "UNKNOWN",
          transaction_id: "txn_100",
          product_id: "com.samansa.subscription.monthly",
          amount: "3.9",
          currency: "USD",
          purchase_date: "2025-10-01T12:00:00Z",
          expires_date: "2025-11-01T12:00:00Z"
        ).permit!
      end

      it "records the event as failed" do
        result = described_class.call(unknown_params)

        expect(result).not_to be_success
        event = AppleWebhookEvent.last
        expect(event.processing_status).to eq("failed")
        expect(event.error_message).to include("Unknown event type")
      end
    end

    context "when subscription not found" do
      let(:missing_params) do
        ActionController::Parameters.new(
          notification_uuid: "notif_005",
          type: "PURCHASE",
          transaction_id: "txn_nonexistent",
          product_id: "com.samansa.subscription.monthly",
          amount: "3.9",
          currency: "USD",
          purchase_date: "2025-10-01T12:00:00Z",
          expires_date: "2025-11-01T12:00:00Z"
        ).permit!
      end

      it "records the event as failed" do
        result = described_class.call(missing_params)

        expect(result).not_to be_success
        event = AppleWebhookEvent.last
        expect(event.processing_status).to eq("failed")
      end
    end
  end
end

require "rails_helper"

RSpec.describe "Api::V1::Apple::Webhooks", type: :request do
  let!(:subscription) { create(:subscription, transaction_id: "txn_200") }

  describe "POST /api/v1/apple/webhooks" do
    context "PURCHASE event" do
      let(:params) do
        {
          notification_uuid: "notif_100",
          type: "PURCHASE",
          transaction_id: "txn_200",
          product_id: "com.samansa.subscription.monthly",
          amount: "3.9",
          currency: "USD",
          purchase_date: Time.current.iso8601,
          expires_date: 1.month.from_now.iso8601
        }
      end

      it "returns 200 and activates subscription" do
        post "/api/v1/apple/webhooks", params: params, as: :json

        expect(response).to have_http_status(:ok)
        expect(subscription.reload.status).to eq("active")
        expect(subscription.watchable?).to be true
      end
    end

    context "RENEW event" do
      before do
        subscription.update!(
          status: "active",
          current_period_start: "2025-10-01T12:00:00Z",
          current_period_end: "2025-11-01T12:00:00Z"
        )
      end

      let(:params) do
        {
          notification_uuid: "notif_101",
          type: "RENEW",
          transaction_id: "txn_200",
          product_id: "com.samansa.subscription.monthly",
          amount: "3.9",
          currency: "USD",
          purchase_date: "2025-11-01T12:00:00Z",
          expires_date: "2025-12-01T12:00:00Z"
        }
      end

      it "returns 200 and extends subscription period" do
        post "/api/v1/apple/webhooks", params: params, as: :json

        expect(response).to have_http_status(:ok)
        subscription.reload
        expect(subscription.status).to eq("active")
        expect(subscription.current_period_start).to eq(Time.parse("2025-11-01T12:00:00Z"))
        expect(subscription.current_period_end).to eq(Time.parse("2025-12-01T12:00:00Z"))
      end
    end

    context "CANCEL event" do
      before do
        subscription.update!(
          status: "active",
          current_period_start: Time.current,
          current_period_end: 1.month.from_now
        )
      end

      let(:params) do
        {
          notification_uuid: "notif_102",
          type: "CANCEL",
          transaction_id: "txn_200",
          product_id: "com.samansa.subscription.monthly",
          amount: "3.9",
          currency: "USD",
          purchase_date: Time.current.iso8601,
          expires_date: 1.month.from_now.iso8601
        }
      end

      it "returns 200 and cancels subscription" do
        post "/api/v1/apple/webhooks", params: params, as: :json

        expect(response).to have_http_status(:ok)
        subscription.reload
        expect(subscription.status).to eq("cancelled")
        expect(subscription.cancelled_at).to be_present
      end

      it "remains watchable until expires_date (解約時でも有効期限まで利用可能)" do
        post "/api/v1/apple/webhooks", params: params, as: :json

        subscription.reload
        expect(subscription.status).to eq("cancelled")
        expect(subscription.watchable?).to be true
        expect(subscription.current_period_end).to be > Time.current
      end
    end

    context "duplicate notification (idempotency)" do
      let(:params) do
        {
          notification_uuid: "notif_dup",
          type: "PURCHASE",
          transaction_id: "txn_200",
          product_id: "com.samansa.subscription.monthly",
          amount: "3.9",
          currency: "USD",
          purchase_date: "2025-10-01T12:00:00Z",
          expires_date: "2025-11-01T12:00:00Z"
        }
      end

      it "returns 200 on duplicate without reprocessing" do
        post "/api/v1/apple/webhooks", params: params, as: :json
        expect(response).to have_http_status(:ok)

        post "/api/v1/apple/webhooks", params: params, as: :json
        expect(response).to have_http_status(:ok)
        expect(AppleWebhookEvent.count).to eq(1)
      end
    end

    context "unknown transaction_id" do
      let(:params) do
        {
          notification_uuid: "notif_unknown",
          type: "PURCHASE",
          transaction_id: "txn_nonexistent",
          product_id: "com.samansa.subscription.monthly",
          amount: "3.9",
          currency: "USD",
          purchase_date: "2025-10-01T12:00:00Z",
          expires_date: "2025-11-01T12:00:00Z"
        }
      end

      it "returns 200 even on failure (never fail Apple)" do
        post "/api/v1/apple/webhooks", params: params, as: :json

        expect(response).to have_http_status(:ok)
        expect(AppleWebhookEvent.last.processing_status).to eq("failed")
      end
    end

    context "full lifecycle integration" do
      it "follows provisional -> PURCHASE -> RENEW -> CANCEL flow" do
        # Step 1: Client creates provisional subscription
        post "/api/v1/subscriptions", params: {
          user_id: "user_lifecycle",
          transaction_id: "txn_lifecycle",
          product_id: "com.samansa.subscription.monthly"
        }, as: :json
        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["status"]).to eq("provisional")
        expect(json["watchable"]).to be false

        # Step 2: Apple sends PURCHASE webhook
        post "/api/v1/apple/webhooks", params: {
          notification_uuid: "lifecycle_purchase",
          type: "PURCHASE",
          transaction_id: "txn_lifecycle",
          product_id: "com.samansa.subscription.monthly",
          amount: "3.9",
          currency: "USD",
          purchase_date: Time.current.iso8601,
          expires_date: 1.month.from_now.iso8601
        }, as: :json
        expect(response).to have_http_status(:ok)

        get "/api/v1/subscriptions/txn_lifecycle"
        json = JSON.parse(response.body)
        expect(json["status"]).to eq("active")
        expect(json["watchable"]).to be true

        # Step 3: Apple sends RENEW webhook
        post "/api/v1/apple/webhooks", params: {
          notification_uuid: "lifecycle_renew",
          type: "RENEW",
          transaction_id: "txn_lifecycle",
          product_id: "com.samansa.subscription.monthly",
          amount: "3.9",
          currency: "USD",
          purchase_date: 1.month.from_now.iso8601,
          expires_date: 2.months.from_now.iso8601
        }, as: :json
        expect(response).to have_http_status(:ok)

        get "/api/v1/subscriptions/txn_lifecycle"
        json = JSON.parse(response.body)
        expect(json["status"]).to eq("active")
        expect(json["watchable"]).to be true

        # Step 4: Apple sends CANCEL webhook
        post "/api/v1/apple/webhooks", params: {
          notification_uuid: "lifecycle_cancel",
          type: "CANCEL",
          transaction_id: "txn_lifecycle",
          product_id: "com.samansa.subscription.monthly",
          amount: "3.9",
          currency: "USD",
          purchase_date: 1.month.from_now.iso8601,
          expires_date: 2.months.from_now.iso8601
        }, as: :json
        expect(response).to have_http_status(:ok)

        get "/api/v1/subscriptions/txn_lifecycle"
        json = JSON.parse(response.body)
        expect(json["status"]).to eq("cancelled")
        expect(json["watchable"]).to be true  # Still watchable until period ends

        # Verify analytics data
        sub = Subscription.find_by(transaction_id: "txn_lifecycle")
        expect(sub.subscription_periods.count).to eq(2)  # PURCHASE + RENEW
        expect(AppleWebhookEvent.count).to be >= 3
      end
    end
  end
end

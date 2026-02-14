require "rails_helper"

RSpec.describe "Api::V1::Subscriptions", type: :request do
  describe "POST /api/v1/subscriptions" do
    let(:valid_params) do
      {
        user_id: "user_123",
        transaction_id: "txn_abc",
        product_id: "com.samansa.subscription.monthly"
      }
    end

    context "with valid params" do
      it "creates a provisional subscription" do
        post "/api/v1/subscriptions", params: valid_params, as: :json

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["status"]).to eq("provisional")
        expect(json["watchable"]).to be false
        expect(json["transaction_id"]).to eq("txn_abc")
      end

      it "is idempotent with same transaction_id" do
        post "/api/v1/subscriptions", params: valid_params, as: :json
        expect(response).to have_http_status(:created)

        post "/api/v1/subscriptions", params: valid_params, as: :json
        expect(response).to have_http_status(:created)
        expect(Subscription.count).to eq(1)
      end
    end

    context "with missing required fields" do
      it "returns unprocessable entity when user_id is blank" do
        post "/api/v1/subscriptions", params: {
          user_id: "", transaction_id: "txn_1", product_id: "plan_1"
        }, as: :json

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "GET /api/v1/subscriptions/:transaction_id" do
    context "when subscription exists" do
      let!(:subscription) { create(:subscription, :active, transaction_id: "txn_lookup") }

      it "returns the subscription" do
        get "/api/v1/subscriptions/txn_lookup"

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["transaction_id"]).to eq("txn_lookup")
        expect(json["status"]).to eq("active")
        expect(json["watchable"]).to be true
      end
    end

    context "when subscription does not exist" do
      it "returns not found" do
        get "/api/v1/subscriptions/txn_nonexistent"

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end

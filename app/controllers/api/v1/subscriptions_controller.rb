module Api
  module V1
    class SubscriptionsController < ApplicationController
      def create
        result = Subscriptions::CreateProvisionalService.call(
          user_id: subscription_params[:user_id],
          transaction_id: subscription_params[:transaction_id],
          product_id: subscription_params[:product_id]
        )

        if result.success?
          render json: SubscriptionSerializer.new(result.subscription).as_json, status: :created
        else
          render json: { error: result.error }, status: result.status
        end
      end

      def show
        subscription = Subscription.find_by!(transaction_id: params[:id])
        render json: SubscriptionSerializer.new(subscription).as_json
      end

      private

      def subscription_params
        params.permit(:user_id, :transaction_id, :product_id)
      end
    end
  end
end

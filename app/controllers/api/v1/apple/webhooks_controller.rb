module Api
  module V1
    module Apple
      class WebhooksController < ApplicationController
        def create
          result = Webhooks::Apple::ProcessEventService.call(webhook_params)

          if result.success? || result.duplicate?
            render json: { status: "ok" }, status: :ok
          else
            Rails.logger.error("Webhook processing failed: #{result.error}")
            render json: { status: "ok" }, status: :ok
          end
        end

        private

        def webhook_params
          params.permit(
            :notification_uuid, :type, :transaction_id,
            :product_id, :amount, :currency,
            :purchase_date, :expires_date
          )
        end
      end
    end
  end
end

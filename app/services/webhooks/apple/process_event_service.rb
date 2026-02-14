module Webhooks
  module Apple
    class ProcessEventService
      HANDLERS = {
        "PURCHASE" => Webhooks::Apple::PurchaseHandler,
        "RENEW" => Webhooks::Apple::RenewHandler,
        "CANCEL" => Webhooks::Apple::CancelHandler
      }.freeze

      def self.call(params)
        new(params).call
      end

      def initialize(params)
        @params = params
      end

      def call
        event = create_event_record
        return ServiceResult.duplicate if event.nil?

        handler_class = HANDLERS[@params[:type]]
        unless handler_class
          event.failed!("Unknown event type: #{@params[:type]}")
          return ServiceResult.failure(error: "Unknown event type")
        end

        ActiveRecord::Base.transaction do
          handler_class.new(event: event, params: @params).call
        end

        event.processed!
        ServiceResult.success(subscription: nil)
      rescue StandardError => e
        event&.failed!(e.message)
        Rails.logger.error("Webhook processing error: #{e.message}")
        ServiceResult.failure(error: e.message)
      end

      private

      # 冪等性: 重複Webhookを検知 / Idempotency: detect duplicate webhooks
      def create_event_record
        AppleWebhookEvent.create!(
          notification_uuid: @params[:notification_uuid],
          event_type: @params[:type],
          transaction_id: @params[:transaction_id],
          product_id: @params[:product_id],
          amount: @params[:amount],
          currency: @params[:currency],
          purchase_date: @params[:purchase_date],
          expires_date: @params[:expires_date],
          raw_payload: @params.to_json,
          processing_status: "pending"
        )
      rescue ActiveRecord::RecordNotUnique
        nil
      rescue ActiveRecord::RecordInvalid => e
        # notification_uuid重複以外のバリデーションエラーは再送出 / Re-raise unless it's a duplicate notification
        raise unless e.message.include?("Notification uuid has already been taken")
        nil
      end
    end
  end
end

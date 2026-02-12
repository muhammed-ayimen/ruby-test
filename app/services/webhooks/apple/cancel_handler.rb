module Webhooks
  module Apple
    class CancelHandler
      def initialize(event:, params:)
        @event = event
        @params = params
      end

      def call
        subscription = Subscription.find_by!(transaction_id: @params[:transaction_id])

        return unless subscription.may_cancel?

        subscription.cancel!
        subscription.update!(
          cancelled_at: Time.current,
          current_period_end: @params[:expires_date]
        )
      end
    end
  end
end

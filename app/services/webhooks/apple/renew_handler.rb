module Webhooks
  module Apple
    class RenewHandler
      def initialize(event:, params:)
        @event = event
        @params = params
      end

      def call
        subscription = Subscription.find_by!(transaction_id: @params[:transaction_id])

        return unless subscription.may_renew?

        subscription.renew!
        subscription.update!(
          current_period_start: @params[:purchase_date],
          current_period_end: @params[:expires_date]
        )

        subscription.subscription_periods.create!(
          event_type: "RENEW",
          amount: @params[:amount],
          currency: @params[:currency],
          starts_at: @params[:purchase_date],
          ends_at: @params[:expires_date]
        )
      end
    end
  end
end

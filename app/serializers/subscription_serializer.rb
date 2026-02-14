class SubscriptionSerializer
  def initialize(subscription)
    @subscription = subscription
  end

  def as_json(_options = {})
    {
      transaction_id: @subscription.transaction_id,
      user_id: @subscription.user_id,
      product_id: @subscription.product_id,
      status: @subscription.status,
      watchable: @subscription.watchable?,
      current_period_start: @subscription.current_period_start&.iso8601,
      current_period_end: @subscription.current_period_end&.iso8601,
      cancelled_at: @subscription.cancelled_at&.iso8601,
      created_at: @subscription.created_at.iso8601,
      updated_at: @subscription.updated_at.iso8601
    }
  end
end

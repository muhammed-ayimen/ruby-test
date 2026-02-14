module Subscriptions
  class CreateProvisionalService
    def self.call(**args)
      new(**args).call
    end

    def initialize(user_id:, transaction_id:, product_id:)
      @user_id = user_id
      @transaction_id = transaction_id
      @product_id = product_id
    end

    def call
      existing = Subscription.find_by(transaction_id: @transaction_id)
      return ServiceResult.success(subscription: existing) if existing

      subscription = Subscription.create!(
        user_id: @user_id,
        transaction_id: @transaction_id,
        product_id: @product_id,
        status: "provisional"
      )

      ServiceResult.success(subscription: subscription)
    rescue ActiveRecord::RecordInvalid => e
      ServiceResult.failure(error: e.message)
    rescue ActiveRecord::RecordNotUnique
      # 冪等性の保証 / Idempotency: handle race condition
      subscription = Subscription.find_by!(transaction_id: @transaction_id)
      ServiceResult.success(subscription: subscription)
    end
  end
end

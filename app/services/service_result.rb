class ServiceResult
  attr_reader :subscription, :error, :status

  def self.success(subscription:)
    new(success: true, subscription: subscription)
  end

  def self.failure(error:, status: :unprocessable_entity)
    new(success: false, error: error, status: status)
  end

  def self.duplicate
    new(success: false, duplicate: true)
  end

  def initialize(success: false, subscription: nil, error: nil, status: nil, duplicate: false)
    @success = success
    @subscription = subscription
    @error = error
    @status = status
    @duplicate = duplicate
  end

  def success?
    @success
  end

  def duplicate?
    @duplicate
  end
end

class AppleWebhookEvent < ApplicationRecord
  validates :notification_uuid, presence: true, uniqueness: true
  validates :event_type, presence: true
  validates :transaction_id, presence: true

  scope :pending, -> { where(processing_status: "pending") }
  scope :failed, -> { where(processing_status: "failed") }

  def processed!
    update!(processing_status: "processed")
  end

  def failed!(message)
    update!(processing_status: "failed", error_message: message)
  end
end

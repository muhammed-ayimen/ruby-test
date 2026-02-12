class SubscriptionPeriod < ApplicationRecord
  belongs_to :subscription

  validates :event_type, presence: true, inclusion: { in: %w[PURCHASE RENEW] }
  validates :starts_at, presence: true
  validates :ends_at, presence: true
  validates :amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  scope :chronological, -> { order(starts_at: :asc) }
end

class Subscription < ApplicationRecord
  include AASM

  has_many :subscription_periods, dependent: :destroy

  validates :user_id, presence: true
  validates :transaction_id, presence: true, uniqueness: true
  validates :product_id, presence: true
  validates :status, presence: true

  scope :for_user, ->(user_id) { where(user_id: user_id) }
  scope :viewable, -> {
    where(status: %w[active cancelled])
      .where("current_period_end > ?", Time.current)
  }

  aasm column: :status, whiny_transitions: true do
    state :provisional, initial: true
    state :active
    state :cancelled
    state :expired

    event :activate do
      transitions from: :provisional, to: :active
    end

    event :renew do
      transitions from: :active, to: :active
    end

    event :cancel do
      transitions from: :active, to: :cancelled
    end

    event :expire do
      transitions from: %i[provisional cancelled], to: :expired
    end
  end

  def watchable?
    status.in?(%w[active cancelled]) &&
      current_period_end.present? &&
      current_period_end > Time.current
  end
end

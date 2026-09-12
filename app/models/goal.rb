class Goal < ApplicationRecord
  include Iconable

  belongs_to :savings
  has_many :goal_contributions, dependent: :destroy
  validates :name, :target_cents, presence: true

  def current_cents
    goal_contributions.sum(:amount_cents)
  end

  def percent_complete
    return 0 if target_cents.to_i.zero?
    ((current_cents.to_f / target_cents) * 100).round
  end

  def completed?
    completed_at.present?
  end

  def target
    target_cents && target_cents / 100.0
  end

  def target=(value)
    self.target_cents = value.present? ? (value.to_f * 100).round : nil
  end
end

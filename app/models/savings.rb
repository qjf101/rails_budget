class Savings < ApplicationRecord
  belongs_to :user
  has_many :goals, dependent: :destroy
  has_many :goal_contributions, dependent: :destroy

  def current_cents
    goal_contributions.sum(:amount_cents)
  end

  def unallocated_cents
    goal_contributions.where(goal_id: nil).sum(:amount_cents)
  end

  def goals_target_cents
    goals.sum(:target_cents)
  end

  def goals_current_cents
    goal_contributions.where.not(goal_id: nil).sum(:amount_cents)
  end

  def goals_percent_complete
    return 0 if goals_target_cents.zero?
    ((goals_current_cents.to_f / goals_target_cents) * 100).round
  end
end

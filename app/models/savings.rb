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
end

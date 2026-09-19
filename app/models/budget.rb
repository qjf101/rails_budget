class Budget < ApplicationRecord
  belongs_to :user
  has_many :budget_allocations, dependent: :destroy
  has_many :categories, through: :budget_allocations

  validates :month, uniqueness: { scope: :user_id }
  before_validation { self.month = month&.beginning_of_month }

  def self.for_month(user, date = Date.current)
    find_or_create_by!(user: user, month: date.beginning_of_month)
  end
end

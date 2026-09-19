class BudgetAllocation < ApplicationRecord
  belongs_to :budget
  belongs_to :category
  validates :category_id, uniqueness: { scope: :budget_id }
end

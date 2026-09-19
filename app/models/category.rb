class Category < ApplicationRecord
  include Iconable

  belongs_to :user
  has_many :transactions, dependent: :nullify
  has_many :budget_allocations, dependent: :destroy

  enum :category_type, { expense: "expense", income: "income" }, default: :expense
  validates :name, presence: true
  default_scope { order(:position) }
end

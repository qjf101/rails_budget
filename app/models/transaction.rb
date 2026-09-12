class Transaction < ApplicationRecord
  belongs_to :user
  belongs_to :category, optional: true
  has_many :goal_contributions, foreign_key: :transaction_id, dependent: :destroy, inverse_of: :source_transaction

  enum :transaction_type, { expense: "expense", income: "income" }
  enum :source, { manual: "manual", bank_sync: "bank_sync" }, default: :manual

  validates :date, :amount_cents, presence: true
  scope :in_month, ->(date) { where(date: date.beginning_of_month..date.end_of_month) }

  accepts_nested_attributes_for :goal_contributions, allow_destroy: true, reject_if: :all_blank

  def amount
    amount_cents && amount_cents / 100.0
  end

  def amount=(value)
    self.amount_cents = value.present? ? (value.to_f * 100).round : nil
  end
end
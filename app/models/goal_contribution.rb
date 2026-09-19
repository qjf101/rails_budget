class GoalContribution < ApplicationRecord
  belongs_to :savings
  belongs_to :goal, optional: true
  belongs_to :source_transaction, class_name: "Transaction", foreign_key: :transaction_id, optional: true, inverse_of: :goal_contributions

  validates :amount_cents, numericality: { other_than: 0 }
  validates :contributed_at, presence: true
  validate :goal_belongs_to_same_savings
  validate :savings_and_transaction_belong_to_same_user
  validate :does_not_exceed_transaction_amount, if: :source_transaction
  validate :does_not_overdraw_goal, if: :goal
  validate :does_not_overdraw_unallocated_savings, unless: :goal

  before_validation do
    self.savings ||= goal&.savings
    self.contributed_at ||= source_transaction&.date || Date.current
  end

  after_save :mark_goal_completed_if_reached

  def amount
    amount_cents && amount_cents / 100.0
  end

  def amount=(value)
    self.amount_cents = value.present? ? (value.to_f * 100).round : nil
  end

  private

  def goal_belongs_to_same_savings
    return unless goal && savings
    errors.add(:goal, "must belong to the same savings") if goal.savings_id != savings.id
  end

  def savings_and_transaction_belong_to_same_user
    return unless source_transaction && savings
    errors.add(:savings, "must belong to the same user as the transaction") if savings.user_id != source_transaction.user_id
  end

  # Sums the in-memory sibling collection, not a DB requery, so this stays
  # correct when several contributions are staged together on one save (e.g. splitting one
  # transaction across goals) regardless of what's been saved to the DB yet.
  def does_not_exceed_transaction_amount
    # A blank amount on the form leaves this nil, and Integer > nil raises. The
    # transaction's own presence validation reports the real problem; there is
    # nothing to exceed until it has a value.
    return if source_transaction.amount_cents.nil?

    siblings_total = source_transaction.goal_contributions.reject { |gc| gc.marked_for_destruction? || gc.equal?(self) }.sum(&:amount_cents)
    if siblings_total + amount_cents.to_i > source_transaction.amount_cents
      errors.add(:amount_cents, "cannot exceed the transaction amount")
    end
  end

  def does_not_overdraw_goal
    siblings_total = goal.goal_contributions.reject { |gc| gc.marked_for_destruction? || gc.equal?(self) }.sum(&:amount_cents)
    errors.add(:amount_cents, "cannot make the goal balance negative") if siblings_total + amount_cents.to_i < 0
  end

  def does_not_overdraw_unallocated_savings
    return unless savings
    siblings_total = savings.goal_contributions
      .select { |gc| gc.goal_id.nil? && !gc.marked_for_destruction? && !gc.equal?(self) }
      .sum(&:amount_cents)
    errors.add(:amount_cents, "cannot make unallocated savings negative") if siblings_total + amount_cents.to_i < 0
  end

  def mark_goal_completed_if_reached
    return unless goal
    return if goal.completed_at.present?
    goal.update!(completed_at: Time.current) if goal.current_cents >= goal.target_cents
  end
end

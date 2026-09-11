class BudgetSummary
  Row = Struct.new(:category, :spent_cents, :allocated_cents, :percent, keyword_init: true)

  def initialize(user, month = Date.current)
    @user = user
    @budget = Budget.for_month(user, month)
    @month = month.beginning_of_month
  end

  def income_cents = @budget.income_cents.to_i
  def allocated_cents = @budget.budget_allocations.sum(:amount_cents)
  def spent_cents = @user.transactions.expense.in_month(@month).sum(:amount_cents)
  def remaining_cents = income_cents - spent_cents

  def category_breakdown
    spent_by_category = @user.transactions.expense.in_month(@month).group(:category_id).sum(:amount_cents)

    @budget.budget_allocations.includes(:category).map do |allocation|
      spent = spent_by_category[allocation.category_id].to_i
      Row.new(
        category: allocation.category,
        spent_cents: spent,
        allocated_cents: allocation.amount_cents,
        percent: allocation.amount_cents.zero? ? 0 : ((spent.to_f / allocation.amount_cents) * 100).round
      )
    end
  end
end
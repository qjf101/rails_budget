class BudgetSummary
  Row = Struct.new(:category, :spent_cents, :allocated_cents, :percent, keyword_init: true)

  # Stands in for transactions with no category, so unassigned spending still
  # reaches the breakdown instead of silently disappearing from the totals.
  UNCATEGORIZED = Struct.new(:id, :name, :color, :icon).new(nil, "Uncategorized", "#9ca3af", "more-horizontal").freeze

  def initialize(user, month = Date.current)
    @user = user
    @budget = Budget.for_month(user, month)
    @month = month.beginning_of_month
  end

  def income_cents = @budget.income_cents.to_i
  def allocated_cents = @budget.budget_allocations.sum(:amount_cents)
  def spent_cents = @user.transactions.expense.in_month(@month).sum(:amount_cents)
  def remaining_cents = income_cents - spent_cents

  # Every budgeted category, plus anything actually spent on this month that was
  # never budgeted for. Keying off allocations alone hid unbudgeted spending
  # entirely and left the donut's slices disagreeing with its centre total.
  def category_breakdown
    spent_by_category = @user.transactions.expense.in_month(@month).group(:category_id).sum(:amount_cents)
    allocations = @budget.budget_allocations.includes(:category).to_a

    budgeted = allocations.map do |allocation|
      build_row(allocation.category, spent_by_category[allocation.category_id].to_i, allocation.amount_cents.to_i)
    end

    budgeted + unbudgeted_rows(spent_by_category, allocations.map(&:category_id))
  end

  private

  def unbudgeted_rows(spent_by_category, budgeted_ids)
    categories = @user.categories.index_by(&:id)

    spent_by_category
      .reject { |category_id, spent| budgeted_ids.include?(category_id) || spent.to_i.zero? }
      .map { |category_id, spent| build_row(categories[category_id] || UNCATEGORIZED, spent.to_i, 0) }
      .sort_by { |row| -row.spent_cents }
  end

  def build_row(category, spent_cents, allocated_cents)
    Row.new(
      category: category,
      spent_cents: spent_cents,
      allocated_cents: allocated_cents,
      # With nothing budgeted, any spend is wholly over budget — 0% would read as
      # "well within budget", which is the opposite of the truth.
      percent: allocated_cents.zero? ? (spent_cents.positive? ? 100 : 0) : ((spent_cents.to_f / allocated_cents) * 100).round
    )
  end
end

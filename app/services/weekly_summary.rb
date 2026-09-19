# The data behind the weekly summary email. Kept separate from the mailer so it can
# be exercised in the console and reused by a future in-app digest view.
class WeeklySummary
  DAYS = 7

  def initialize(user, week_ending = Date.current)
    @user = user
    @week_ending = week_ending
    @range = (week_ending - (DAYS - 1).days)..week_ending
  end

  attr_reader :range, :week_ending

  def income_cents = totals[:income]
  def expense_cents = totals[:expense]
  def net_cents = income_cents - expense_cents
  def transaction_count = @transaction_count ||= scope.count
  def any_activity? = transaction_count.positive?

  def top_categories
    @top_categories ||= CategorySpending.for(@user, @range, limit: 5)
  end

  # Only categories with a real allocation can be over it — same guard the sweeper uses.
  def over_budget
    @over_budget ||= BudgetSummary.new(@user, @week_ending).category_breakdown
      .select { |row| row.allocated_cents.positive? && row.percent >= 100 }
  end

  def goals
    @goals ||= @user.savings&.goals&.reject(&:completed?)&.first(3) || []
  end

  private

  def scope = @user.transactions.where(date: @range)

  # One grouped query instead of two sums; memoised because the template reads
  # these several times.
  def totals
    @totals ||= begin
      grouped = scope.group(:transaction_type).sum(:amount_cents)
      { income: grouped["income"].to_i, expense: grouped["expense"].to_i }
    end
  end
end

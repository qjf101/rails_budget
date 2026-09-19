class MonthlyCalendar
  PERIODS = %w[monthly weekly daily].freeze

  DaySummary = Struct.new(:date, :income_cents, :expense_cents, :income_count, :expense_count, keyword_init: true) do
    def net_cents = income_cents - expense_cents
    def activity? = income_count.positive? || expense_count.positive?
  end

  def initialize(user, month = Date.current)
    @user = user
    @month = month.beginning_of_month
  end

  def days
    @days ||= begin
      scope = @user.transactions.in_month(@month)
      sums = scope.group(:date, :transaction_type).sum(:amount_cents)
      counts = scope.group(:date, :transaction_type).count

      (@month..@month.end_of_month).map do |date|
        DaySummary.new(
          date: date,
          income_cents: sums[[ date, "income" ]].to_i,
          expense_cents: sums[[ date, "expense" ]].to_i,
          income_count: counts[[ date, "income" ]].to_i,
          expense_count: counts[[ date, "expense" ]].to_i
        )
      end
    end
  end

  # Whole weeks (Mon–Sun) covering the month, so the grid is always rectangular.
  # Days spilling in from the neighbouring months are present but carry no totals.
  def weeks
    by_date = days.index_by(&:date)
    first = @month.beginning_of_week(:monday)
    last = @month.end_of_month.end_of_week(:monday)

    (first..last).to_a.each_slice(7).map do |week|
      week.map { |date| by_date[date] || blank_day(date) }
    end
  end

  def in_month?(date) = date.month == @month.month

  def most_expensive_day
    candidate = days.max_by(&:expense_cents)
    candidate if candidate&.expense_cents&.positive?
  end

  def income_days = days.count { |day| day.income_cents.positive? }
  def spending_days = days.count { |day| day.expense_cents.positive? }

  def income_cents = days.sum(&:income_cents)
  def expense_cents = days.sum(&:expense_cents)
  def remaining_cents = income_cents - expense_cents

  def percent_of_income_left
    return 0 if income_cents.zero?

    ((remaining_cents.to_f / income_cents) * 100).round
  end

  # The Overview panel re-scopes to a period inside (or overlapping) the month.
  def range_for(period, anchor)
    case period
    when "weekly" then anchor.beginning_of_week(:monday)..anchor.end_of_week(:monday)
    when "daily"  then anchor..anchor
    else @month..@month.end_of_month
    end
  end

  def totals_for(range)
    scope = @user.transactions.where(date: range)
    income = scope.income.sum(:amount_cents)
    expense = scope.expense.sum(:amount_cents)
    { income_cents: income, expense_cents: expense, remaining_cents: income - expense }
  end

  def top_categories_for(range, limit: 5)
    CategorySpending.for(@user, range, limit: limit)
  end

  private

  def blank_day(date)
    DaySummary.new(date: date, income_cents: 0, expense_cents: 0, income_count: 0, expense_count: 0)
  end
end

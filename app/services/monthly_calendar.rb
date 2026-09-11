class MonthlyCalendar
  DaySummary = Struct.new(:date, :income_cents, :expense_cents, keyword_init: true)

  def initialize(user, month = Date.current)
    @user = user
    @month = month.beginning_of_month
  end

  def days
    totals = @user.transactions.in_month(@month).group(:date, :transaction_type).sum(:amount_cents)

    (@month..@month.end_of_month).map do |date|
      DaySummary.new(
        date: date,
        income_cents: totals[[date, "income"]].to_i,
        expense_cents: totals[[date, "expense"]].to_i
      )
    end
  end

  def most_expensive_day
    days.max_by(&:expense_cents)
  end

  def top_categories(limit: 5)
    @user.transactions.expense.in_month(@month)
         .joins(:category).group("categories.name")
         .sum(:amount_cents)
         .sort_by { |_, cents| -cents }
         .first(limit)
  end
end
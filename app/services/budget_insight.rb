class BudgetInsight
  Insight = Struct.new(:message, :tip, keyword_init: true)

  def initialize(user)
    @user = user
  end

  def call
    this_week = spent_in(Date.current.beginning_of_week..Date.current.end_of_week)
    last_week = spent_in(1.week.ago.beginning_of_week..1.week.ago.end_of_week)
    top_category, amount_cents = this_week.max_by { |_, cents| cents } || [nil, 0]

    return Insight.new(message: "Log a few transactions to get personalized insights.",
      tip: "Add your first expense to get started.") unless top_category

    last_amount = last_week[top_category].to_i
    change_percent = last_amount.zero? ? 100 : (((amount_cents - last_amount).to_f / last_amount) * 100).round
    direction = change_percent >= 0 ? "more" : "less"

    Insight.new(
      message: "You spent $#{amount_cents / 100} on #{top_category} this week, #{change_percent}% #{direction} than last week.",
      tip: "Consider planning ahead to stay under budget for #{top_category}."
    )
  end

  private

  def spent_in(range)
    @user.transactions.expense.where(date: range).joins(:category).group("categories.name").sum(:amount_cents)
  end
end
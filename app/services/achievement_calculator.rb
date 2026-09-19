class AchievementCalculator
  Achievement = Struct.new(:key, :title, :description, :icon, :unlocked, keyword_init: true)

  def initialize(user)
    @user = user
  end

  def unlocked = all.select(&:unlocked)

  def all
    [
      Achievement.new(key: :first_budget, title: "First Budget Created",
        description: "Great start on your financial journey!", icon: "trophy",
        unlocked: @user.budgets.exists?),
      Achievement.new(key: :streak_14, title: "14 Day Streak",
        description: "Logged transactions 14 days in a row.", icon: "flame",
        unlocked: logging_streak >= 14),
      Achievement.new(key: :saved_10k, title: "Saved $10,000",
        description: "You have saved $10,000 so far.", icon: "piggy-bank",
        unlocked: total_saved_cents >= 10_000_00),
      Achievement.new(key: :under_budget, title: "Stayed Under Budget",
        description: "You stayed under budget this week.", icon: "shield-check",
        unlocked: under_budget_this_week?)
    ]
  end

  private

  def logging_streak
    dates = @user.transactions.distinct.pluck(:date).sort.reverse
    return 0 if dates.empty?
    streak = 1
    dates.each_cons(2) { |a, b| (a - b).to_i == 1 ? streak += 1 : break }
    streak
  end

  def total_saved_cents
    savings_category = @user.categories.find_by(name: "Savings")
    return 0 unless savings_category
    @user.transactions.expense.where(category: savings_category).sum(:amount_cents)
  end

  def under_budget_this_week?
    week = Date.current.beginning_of_week..Date.current.end_of_week
    spent = @user.transactions.expense.where(date: week).sum(:amount_cents)
    weekly_allocation = Budget.for_month(@user).income_cents.to_i / 4.0
    spent <= weekly_allocation
  end
end

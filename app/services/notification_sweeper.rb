# Looks at the user's current state and reports anything newly true. Deliberately
# not a model callback: this must not fire during seeding, imports or tests, and
# an explicit call site is easier to keep out of those than an opt-out flag.
class NotificationSweeper
  GOAL_MILESTONES = [25, 50, 75, 100].freeze

  def initialize(user, month = Date.current)
    @user = user
    @month = month.beginning_of_month
  end

  def call
    budget_alerts
    goal_milestones
  end

  private

  def budget_alerts
    BudgetSummary.new(@user, @month).category_breakdown.each do |row|
      # category_breakdown also returns unbudgeted spending at a nominal 100%.
      # Only a real allocation can be "over budget".
      next unless row.allocated_cents.positive?
      next unless row.percent >= 100

      Notification.deliver(
        user: @user,
        kind: "budget_alerts",
        dedupe_key: "budget:#{@month}:#{row.category.id}",
        title: "#{row.category.name} is over budget",
        body: "You've spent #{usd(row.spent_cents)} of your #{usd(row.allocated_cents)} budget.",
        url: Rails.application.routes.url_helpers.budget_path
      )
    end
  end

  def goal_milestones
    @user.savings&.goals&.each do |goal|
      reached = GOAL_MILESTONES.select { |threshold| goal.percent_complete >= threshold }
      next if reached.empty?

      # Only the highest crossed milestone is worth telling someone about; the
      # dedupe key keeps the lower ones from firing later.
      threshold = reached.max
      Notification.deliver(
        user: @user,
        kind: "goal_milestones",
        dedupe_key: "goal:#{goal.id}:#{threshold}",
        title: "#{goal.name} hit #{threshold}%",
        body: "#{usd(goal.current_cents)} of #{usd(goal.target_cents)} saved.",
        url: Rails.application.routes.url_helpers.goals_path
      )
    end
  end

  def usd(cents)
    ActionController::Base.helpers.number_to_currency(cents.to_i / 100.0, precision: 0)
  end
end

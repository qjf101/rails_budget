class DashboardController < ApplicationController
  def index
    @summary = BudgetSummary.new(current_user)
    @recent_transactions = current_user.transactions.order(date: :desc).limit(5)
    @achievements = AchievementCalculator.new(current_user).all
    @insight = BudgetInsight.new(current_user).call
  end
end
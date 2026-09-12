class BudgetController < ApplicationController
  def allocate
    @budget = Budget.for_month(current_user)
    @categories = current_user.categories
  end

  def update_allocations
    budget = Budget.for_month(current_user)
    params[:allocations].each do |category_id, amount|
      allocation = budget.budget_allocations.find_or_initialize_by(category: current_user.categories.find(category_id))
      allocation.update!(amount_cents: amount.to_i * 100)
    end
    redirect_to budget_path, notice: "Budget saved."
  end

  def calendar
    month = params[:month].present? ? Date.parse(params[:month]) : Date.current
    @calendar = MonthlyCalendar.new(current_user, month)
    @month = month
  end
end
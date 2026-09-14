class BudgetController < ApplicationController
  def allocate
    @budget = Budget.for_month(current_user)
    # Income has its own field on the budget; allocating to it would double count.
    @categories = current_user.categories.expense
    @allocations = @budget.budget_allocations.index_by(&:category_id)

    @income_cents = @budget.income_cents.to_i
    @allocated_cents = @budget.budget_allocations.sum(:amount_cents)
    @remaining_cents = @income_cents - @allocated_cents
    @allocated_percent = @income_cents.zero? ? 0 : ((@allocated_cents.to_f / @income_cents) * 100).round
  end

  def update_allocations
    budget = Budget.for_month(current_user)
    budget.update!(income_cents: to_cents(params[:income])) if params.key?(:income)

    params.fetch(:allocations, {}).each do |category_id, amount|
      category = current_user.categories.find_by(id: category_id)
      next unless category

      allocation = budget.budget_allocations.find_or_initialize_by(category: category)
      allocation.update!(amount_cents: to_cents(amount))
    end

    redirect_to budget_path, notice: "Budget saved.", status: :see_other
  end

  def calendar
    month = params[:month].present? ? Date.parse(params[:month]) : Date.current
    @calendar = MonthlyCalendar.new(current_user, month)
    @month = month
  end

  private

  # Inputs are dollars; the column is cents. to_f rather than to_i so "1234.50" survives.
  def to_cents(amount)
    (amount.to_s.delete(",$").to_f * 100).round
  end
end

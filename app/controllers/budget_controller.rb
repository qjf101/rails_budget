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

    # Lowering an allocation can put a category over budget without any new spending.
    sweep_notifications
    redirect_to budget_path, notice: "Budget saved.", status: :see_other
  end

  def calendar
    @month = parse_month(params[:month])
    @calendar = MonthlyCalendar.new(current_user, @month)
    @month_options = month_options

    @period = MonthlyCalendar::PERIODS.include?(params[:period]) ? params[:period] : "monthly"
    # Weekly/daily need a day to sit on: today when we're looking at the current
    # month, otherwise the last day of whichever month is on screen.
    @anchor = @month == Date.current.beginning_of_month ? Date.current : @month.end_of_month
    @range = @calendar.range_for(@period, @anchor)
    @totals = @calendar.totals_for(@range)
    @top_categories = @calendar.top_categories_for(@range)
    @insight = BudgetInsight.new(current_user).call
  end

  private

  def parse_month(value)
    value.present? ? Date.parse(value).beginning_of_month : Date.current.beginning_of_month
  rescue Date::Error
    Date.current.beginning_of_month
  end

  def month_options
    12.downto(0).map do |ago|
      month = ago.months.ago(Date.current).beginning_of_month
      [ month.strftime("%B %Y"), month.to_s ]
    end
  end

  # Inputs are dollars; the column is cents. to_f rather than to_i so "1234.50" survives.
  def to_cents(amount)
    (amount.to_s.delete(",$").to_f * 100).round
  end
end

class TransactionsController < ApplicationController
  before_action :set_transaction, only: [ :edit, :update, :destroy ]
  helper_method :savings_category

  PER_PAGE = 12

  RANGE_KEYS = %w[this_month last_3_months last_6_months this_year all].freeze
  DEFAULT_RANGE = "this_month".freeze

  def index
    @categories = current_user.categories
    # The pill shows the resolved span ("Sep 1 – Sep 30, 2026"), not the key.
    @range_options = RANGE_KEYS.map { |key| [ range_label(key), key ] }

    # The summary cards always describe the current month, independent of the filter.
    @month = Date.current
    month_transactions = current_user.transactions.in_month(@month)
    @total_income_cents = month_transactions.income.sum(:amount_cents)
    @total_expense_cents = month_transactions.expense.sum(:amount_cents)
    @net_cents = @total_income_cents - @total_expense_cents
    @income_days = month_transactions.income.distinct.count(:date)
    @spending_days = month_transactions.expense.distinct.count(:date)

    @filters = filter_params
    # Offering expense categories while the Income segment is active would only
    # ever yield empty results.
    @filter_categories = if @filters[:transaction_type]
      @categories.select { |category| category.category_type == @filters[:transaction_type] }
    else
      @categories
    end

    scope = current_user.transactions.includes(:category).order(date: :desc)
    scope = scope.where(category_id: @filters[:category_id]) if @filters[:category_id]
    scope = scope.where(transaction_type: @filters[:transaction_type]) if @filters[:transaction_type]
    if (range = date_range_for(@filters[:range]))
      scope = scope.where(date: range)
    end

    @transactions_count = scope.count
    @total_pages = [ (@transactions_count.to_f / PER_PAGE).ceil, 1 ].max
    @page = params[:page].to_i.clamp(1, @total_pages)
    @offset = (@page - 1) * PER_PAGE
    @transactions = scope.limit(PER_PAGE).offset(@offset)
  end

  def new
    @transaction = current_user.transactions.new(date: Date.current, transaction_type: :expense)
    load_form_data
  end

  def create
    @transaction = current_user.transactions.new(transaction_params)
    sync_goal_split

    if @transaction.save
      sweep_notifications
      close_modal_and_reload("Transaction added.")
    else
      load_form_data
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    load_form_data
  end

  def update
    @transaction.assign_attributes(transaction_params)
    sync_goal_split

    if @transaction.save
      sweep_notifications
      close_modal_and_reload("Transaction updated.")
    else
      load_form_data
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @transaction.destroy
    redirect_to transactions_path, notice: "Transaction removed.", status: :see_other
  end

  private

  def load_form_data
    @categories = current_user.categories
    @goals = current_user.savings&.goals.to_a
    # On a re-render the submitted split wins; opening Edit falls back to the split already saved.
    @goal_allocations = submitted_goal_allocations || persisted_goal_allocations
  end

  # The keys are goal ids, so permit exactly the ones this user owns rather than
  # permit!. Anything else in the hash is dropped instead of being carried along.
  def submitted_goal_allocations
    submitted = params[:goal_allocations]
    return nil if submitted.blank?

    submitted.permit(*@goals.map { |goal| goal.id.to_s }).to_h
  end

  def persisted_goal_allocations
    return {} unless @transaction&.persisted?

    @transaction.goal_contributions.each_with_object({}) do |contribution, allocations|
      allocations[contribution.goal_id.to_s] = contribution.amount if contribution.goal_id
    end
  end

  # A Savings transaction can be divided across goals; whatever is left over is
  # recorded as an unallocated contribution ("General Savings"). The form submits the
  # whole split every time, so the previous one is discarded rather than merged into
  # — which also clears the split when a transaction moves out of the Savings category.
  def sync_goal_split
    savings = current_user.savings
    return unless savings

    @transaction.goal_contributions.each(&:mark_for_destruction)
    return unless @transaction.category == savings_category

    allocated_cents = 0
    savings.goals.each do |goal|
      cents = ((params.dig(:goal_allocations, goal.id.to_s).presence || 0).to_f * 100).round
      next unless cents.positive?

      allocated_cents += cents
      @transaction.goal_contributions.build(savings: savings, goal: goal, amount_cents: cents)
    end

    remainder = @transaction.amount_cents.to_i - allocated_cents
    @transaction.goal_contributions.build(savings: savings, amount_cents: remainder) if remainder.positive?
  end

  # defined? rather than ||= so a user with no Savings category isn't re-queried.
  def savings_category
    return @savings_category if defined?(@savings_category)

    @savings_category = current_user.categories.find_by(name: "Savings")
  end

  # The form lives in a turbo frame, so a plain redirect would only swap the frame
  # and leave a stale list behind. A refresh stream reloads the page underneath.
  def close_modal_and_reload(message)
    respond_to do |format|
      format.turbo_stream do
        # Not turbo_stream.refresh: that stamps a request id, which Turbo then
        # recognises as its own and skips. The bare action always reloads.
        flash[:notice] = message
        render turbo_stream: turbo_stream.action(:refresh, "")
      end
      format.html { redirect_to transactions_path, notice: message, status: :see_other }
    end
  end

  # Only the filters we recognise survive, so they can be safely round-tripped
  # into pagination links and back into the query.
  def filter_params
    filters = { range: RANGE_KEYS.include?(params[:range]) ? params[:range] : DEFAULT_RANGE }
    filters[:category_id] = params[:category_id] if params[:category_id].present?
    filters[:transaction_type] = params[:transaction_type] if Transaction.transaction_types.key?(params[:transaction_type])

    # Switching segments drops a category that belongs to the other type, rather
    # than silently showing an empty list.
    if filters[:category_id] && filters[:transaction_type]
      category = current_user.categories.find_by(id: filters[:category_id])
      filters.delete(:category_id) if category && category.category_type != filters[:transaction_type]
    end

    filters
  end

  # nil means "no date constraint" — the All Time option.
  def date_range_for(key)
    today = Date.current
    case key
    when "this_month"    then today.beginning_of_month..today.end_of_month
    when "last_3_months" then 2.months.ago(today).beginning_of_month..today.end_of_month
    when "last_6_months" then 5.months.ago(today).beginning_of_month..today.end_of_month
    when "this_year"     then today.beginning_of_year..today.end_of_year
    end
  end

  def range_label(key)
    range = date_range_for(key)
    return "All Time" if range.nil?

    "#{range.first.strftime("%b %-d")} – #{range.last.strftime("%b %-d, %Y")}"
  end

  def set_transaction
    @transaction = current_user.transactions.find(params[:id])
  end

  def transaction_params
    params.require(:transaction).permit(:date, :amount, :transaction_type, :category_id, :description, :notes,
      goal_contributions_attributes: [ :id, :goal_id, :amount, :_destroy ])
  end
end

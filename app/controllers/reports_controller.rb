class ReportsController < ApplicationController
  RANGES = {
    "last_3_months"  => "Last 3 Months",
    "last_6_months"  => "Last 6 Months",
    "last_12_months" => "Last 12 Months",
    "this_year"      => "This Year"
  }.freeze
  DEFAULT_RANGE = "last_6_months".freeze

  def index
    @range_key = RANGES.key?(params[:range]) ? params[:range] : DEFAULT_RANGE
    @range_options = RANGES.map { |key, label| [ label, key ] }
    @range = date_range_for(@range_key)

    scope = current_user.transactions.where(date: @range)
    @income_cents = scope.income.sum(:amount_cents)
    @expense_cents = scope.expense.sum(:amount_cents)
    @net_cents = @income_cents - @expense_cents
    @saved_percent = @income_cents.zero? ? 0 : ((@net_cents.to_f / @income_cents) * 100).round

    @months = months_in(@range)
    @chart_series = monthly_series(scope)
    @categories = CategorySpending.for(current_user, @range)
  end

  private

  def date_range_for(key)
    today = Date.current
    case key
    when "last_3_months"  then 2.months.ago(today).beginning_of_month..today.end_of_month
    when "last_12_months" then 11.months.ago(today).beginning_of_month..today.end_of_month
    when "this_year"      then today.beginning_of_year..today.end_of_year
    else 5.months.ago(today).beginning_of_month..today.end_of_month
    end
  end

  def months_in(range)
    month = range.first.beginning_of_month
    last = range.last.beginning_of_month
    [].tap do |months|
      while month <= last
        months << month
        month = month.next_month
      end
    end
  end

  # One grouped query for the whole range; empty months still get a zero column
  # so the chart keeps a steady shape as the range changes.
  def monthly_series(scope)
    totals = scope.group_by_month(:date).group(:transaction_type).sum(:amount_cents)

    # Chartkick halves the opacity of every non-line series; a per-series `library`
    # hash is merged straight into the Chart.js dataset, which restores solid bars.
    [
      { name: "Income",   data: @months.to_h { |m| [ m.strftime("%b"), totals[[ m, "income" ]].to_i / 100.0 ] },
        library: { backgroundColor: "#16a34a", borderRadius: 6, borderWidth: 0 } },
      { name: "Expenses", data: @months.to_h { |m| [ m.strftime("%b"), totals[[ m, "expense" ]].to_i / 100.0 ] },
        library: { backgroundColor: "#ef4444", borderRadius: 6, borderWidth: 0 } }
    ]
  end
end

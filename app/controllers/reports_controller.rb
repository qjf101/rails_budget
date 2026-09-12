class ReportsController < ApplicationController
  def index
    @monthly_totals = current_user.transactions
      .group_by_month(:date, last: 6)
      .group(:transaction_type)
      .sum(:amount_cents)
  end
end
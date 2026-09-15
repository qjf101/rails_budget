# Expense totals per category over an arbitrary date range, shared by the Reports
# breakdown and the Calendar's "Top Spending Categories" panel.
class CategorySpending
  Row = Struct.new(:name, :color, :icon, :cents, :percent, keyword_init: true)

  def self.for(user, range, limit: nil)
    totals = user.transactions.expense.where(date: range)
                 .joins(:category)
                 .group("categories.name", "categories.color", "categories.icon")
                 .sum(:amount_cents)
    spent = totals.values.sum

    rows = totals.sort_by { |_, cents| -cents }
    rows = rows.first(limit) if limit

    rows.map do |(name, color, icon), cents|
      Row.new(
        name: name, color: color, icon: icon, cents: cents,
        # One decimal: the Reports legend shows 46.4%, the Calendar rounds it off.
        percent: spent.zero? ? 0.0 : ((cents.to_f / spent) * 100).round(1)
      )
    end
  end
end

# Suggested share of take-home income per category, used for the "Recommended"
# hint under each allocation input and for the "Use Automatic Plan" button.
class BudgetPlanner
  RANGES = {
    "Housing"           => 25..35,
    "Food & Dining"     => 10..15,
    "Transport"         => 5..10,
    "Shopping"          => 5..10,
    "Entertainment"     => 5..10,
    "Bills & Utilities" => 5..10,
    "Savings"           => 15..20,
    "Other"             => 5..10,
  }.freeze

  # Anything the user adds beyond the seeded set gets a modest default.
  DEFAULT_RANGE = (5..10).freeze

  def self.range_for(category)
    RANGES.fetch(category.name, DEFAULT_RANGE)
  end

  def self.label_for(category)
    range = range_for(category)
    "Recommended: #{range.first}–#{range.last}%"
  end

  # The midpoint of the range. The seeded set sums to 97.5%, leaving a little slack.
  def self.suggested_cents(category, income_cents)
    range = range_for(category)
    midpoint = (range.first + range.last) / 2.0
    (income_cents.to_i * midpoint / 100).round
  end
end

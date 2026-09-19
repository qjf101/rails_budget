user = User.find_or_create_by!(email: ENV.fetch("DEMO_USER_EMAIL", "demo@example.com")) do |u|
  u.password = "password123"
end

categories = [
  { name: "Housing",           icon: "home",            color: "#3b82f6" },
  { name: "Food & Dining",     icon: "utensils",        color: "#ef4444" },
  { name: "Transport",         icon: "car",             color: "#8b5cf6" },
  { name: "Shopping",          icon: "shopping-bag",    color: "#f59e0b" },
  { name: "Entertainment",     icon: "film",            color: "#f97316" },
  { name: "Bills & Utilities", icon: "file-text",       color: "#06b6d4" },
  { name: "Savings",           icon: "piggy-bank",      color: "#3b82f6" },
  { name: "Other",             icon: "more-horizontal", color: "#6b7280" },
].map.with_index do |attrs, i|
  user.categories.find_or_create_by!(name: attrs[:name]) do |c|
    c.icon = attrs[:icon]
    c.color = attrs[:color]
    c.position = i
  end
end

income_category = user.categories.find_or_create_by!(name: "Income") do |c|
  c.icon = "dollar-sign"
  c.color = "#22c55e"
  c.category_type = :income
  c.position = categories.size
end

budget = Budget.for_month(user, Date.current)
budget.update!(income_cents: 4_500_00)

allocations = {
  "Housing" => 1_200_00, "Food & Dining" => 500_00, "Transport" => 250_00,
  "Shopping" => 400_00, "Entertainment" => 300_00, "Bills & Utilities" => 700_00,
  "Savings" => 800_00, "Other" => 250_00,
}
categories.each do |category|
  BudgetAllocation.find_or_create_by!(budget: budget, category: category) do |a|
    a.amount_cents = allocations.fetch(category.name)
  end
end

merchant_names = {
  "Housing"           => ["Rent Payment", "Mortgage Payment", "HOA Fees"],
  "Food & Dining"     => ["Whole Foods", "Chipotle", "Starbucks", "DoorDash", "Corner Diner"],
  "Transport"         => ["Uber", "Shell Gas Station", "Metro Transit", "Lyft"],
  "Shopping"          => ["Amazon", "Target", "Best Buy", "H&M"],
  "Entertainment"     => ["Netflix", "AMC Theatres", "Spotify", "Steam"],
  "Bills & Utilities" => ["Electric Company", "Internet Provider", "Water Utility", "Phone Bill"],
  "Savings"           => ["Transfer to Savings", "Emergency Fund Deposit"],
  "Other"             => ["Miscellaneous Purchase", "ATM Withdrawal", "Cash Expense"],
}

25.times do |i|
  user.transactions.find_or_create_by!(external_id: "seed-expense-#{i}") do |t|
    category = categories.sample
    t.date = Date.current.beginning_of_month + rand(0..27).days
    t.category = category
    t.description = merchant_names.fetch(category.name).sample
    t.amount_cents = rand(5..150) * 100
    t.transaction_type = :expense
  end
end

user.transactions.find_or_create_by!(date: Date.current.beginning_of_month + 1.day, description: "Monthly Salary") do |t|
  t.amount_cents = 4_500_00
  t.transaction_type = :income
  t.category = income_category
end

emergency_fund = user.savings.goals.find_or_create_by!(name: "Emergency Fund") do |g|
  g.target_cents = 5_000_00
  g.target_date = 6.months.from_now.to_date
  g.icon = "piggy-bank"
  g.color = "#3b82f6"
end

emergency_fund.goal_contributions.find_or_create_by!(note: "Starting balance") do |c|
  c.amount_cents = 2_100_00
  c.contributed_at = Date.current
end
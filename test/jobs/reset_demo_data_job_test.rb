require "test_helper"

class ResetDemoDataJobTest < ActiveSupport::TestCase
  teardown do
    ENV.delete("DEMO_AUTO_LOGIN")
    ENV.delete("DEMO_USER_EMAIL")
  end

  test "does nothing at all when the feature is off" do
    victim = User.create!(email: "demo@example.com", password: "password123")
    ENV["DEMO_USER_EMAIL"] = victim.email
    # DEMO_AUTO_LOGIN deliberately unset

    ResetDemoDataJob.perform_now

    assert User.exists?(victim.id), "a misconfigured schedule must not be able to wipe an account"
  end

  test "wipes visitor edits and restores the seeded state" do
    ENV["DEMO_AUTO_LOGIN"] = "true"
    ENV["DEMO_USER_EMAIL"] = "demo@example.com"
    load Rails.root.join("db/seeds.rb")

    demo = User.find_by(email: "demo@example.com")
    seeded_categories = demo.categories.count
    seeded_transactions = demo.transactions.count

    # a visitor makes a mess
    junk = demo.categories.create!(name: "Visitor junk", icon: "home", color: "#000000", category_type: :expense)
    demo.transactions.create!(date: Date.current, amount_cents: 999_99, transaction_type: :expense, category: junk)
    demo.savings.goals.create!(name: "Visitor goal", target_cents: 1, icon: "target", color: "#000000")

    ResetDemoDataJob.perform_now

    restored = User.find_by(email: "demo@example.com")
    assert_not_nil restored, "the account must exist again afterwards or auto-login breaks"
    assert_equal seeded_categories, restored.categories.count
    assert_equal seeded_transactions, restored.transactions.count
    assert_empty restored.categories.where(name: "Visitor junk")
    assert_empty restored.savings.goals.where(name: "Visitor goal")
  end

  test "leaves other users untouched" do
    ENV["DEMO_AUTO_LOGIN"] = "true"
    ENV["DEMO_USER_EMAIL"] = "demo@example.com"
    load Rails.root.join("db/seeds.rb")
    bystander = User.create!(email: "real@example.com", password: "password123")
    bystander.categories.create!(name: "Mine", icon: "home", color: "#111111", category_type: :expense)

    ResetDemoDataJob.perform_now

    assert User.exists?(bystander.id)
    assert_equal 1, bystander.categories.count
  end
end

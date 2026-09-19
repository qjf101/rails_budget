require "test_helper"

# Regression: the sweeper was only called from the transactions controller, so
# crossing a goal milestone from the Goals screen produced no notification at all.
class NotificationEmissionTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "emit@example.com", password: "password123")
    @goal = @user.savings.goals.create!(name: "Trip", target_cents: 100_000, icon: "plane", color: "#f97316")
    sign_in @user
  end

  test "adding funds to a goal emits a milestone" do
    assert_difference -> { @user.notifications.where(kind: "goal_milestones").count }, 1 do
      post goal_contributions_path(@goal), params: { goal_contribution: { amount: 600 } }
    end
    assert_equal "Trip hit 50%", @user.notifications.last.title
  end

  test "transferring into a goal emits a milestone" do
    @user.savings.goal_contributions.create!(amount_cents: 80_000)

    assert_difference -> { @user.notifications.where(kind: "goal_milestones").count }, 1 do
      post goal_transfers_path, params: { from_goal_id: "", to_goal_id: @goal.id, amount: 800 }
    end
  end

  test "lowering an allocation can put a category over budget" do
    category = @user.categories.create!(name: "Groceries", icon: "utensils", color: "#ef4444", category_type: :expense)
    @user.transactions.create!(date: Date.current, amount_cents: 9_000, transaction_type: :expense, category: category)

    assert_difference -> { @user.notifications.where(kind: "budget_alerts").count }, 1 do
      patch budget_path, params: { income: 5000, allocations: { category.id.to_s => "50" } }
    end
  end
end

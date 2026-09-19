require "test_helper"

# Regression: this used to be params[:goal_allocations].permit!, which Brakeman
# flagged as mass assignment. The keys are goal ids, so only the current user's are
# permitted now — anything else is dropped rather than carried into the form.
class GoalAllocationParamsTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "alloc@example.com", password: "password123")
    @savings_category = @user.categories.create!(name: "Savings", icon: "piggy-bank", color: "#3b82f6", category_type: :expense)
    @goal = @user.savings.goals.create!(name: "Trip", target_cents: 100_000, icon: "plane", color: "#f97316")

    stranger = User.create!(email: "stranger@example.com", password: "password123")
    @foreign_goal = stranger.savings.goals.create!(name: "Theirs", target_cents: 100_000, icon: "target", color: "#000000")

    sign_in @user
  end

  test "an invalid submission repopulates only this user's allocations" do
    post transactions_path, params: {
      transaction: { date: Date.current, amount: "", transaction_type: "expense", category_id: @savings_category.id },
      goal_allocations: { @goal.id.to_s => "40", @foreign_goal.id.to_s => "999", "bogus" => "1" }
    }

    assert_response :unprocessable_entity
    allocations = @controller.view_assigns["goal_allocations"]

    assert_equal({ @goal.id.to_s => "40" }, allocations)
    assert_not allocations.key?(@foreign_goal.id.to_s), "another user's goal id must not survive"
    assert_not allocations.key?("bogus")
  end

  test "a submission with no allocations falls back to what is saved" do
    transaction = @user.transactions.create!(date: Date.current, amount_cents: 5_000,
      transaction_type: :expense, category: @savings_category)
    transaction.goal_contributions.create!(savings: @user.savings, goal: @goal, amount_cents: 2_500)

    get edit_transaction_path(transaction)

    assert_response :success
    assert_equal({ @goal.id.to_s => 25.0 }, @controller.view_assigns["goal_allocations"])
  end
end

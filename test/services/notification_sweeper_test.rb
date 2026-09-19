require "test_helper"

class NotificationSweeperTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "sweep@example.com", password: "password123")
    @category = @user.categories.create!(name: "Groceries", icon: "utensils", color: "#ef4444", category_type: :expense)
    @budget = Budget.for_month(@user)
    @budget.budget_allocations.create!(category: @category, amount_cents: 10_000)
  end

  def overspend!(cents = 12_000)
    @user.transactions.create!(date: Date.current, amount_cents: cents, transaction_type: :expense, category: @category)
  end

  test "reports a category that has gone over its allocation" do
    overspend!

    assert_difference -> { @user.notifications.count }, 1 do
      NotificationSweeper.new(@user).call
    end

    notification = @user.notifications.last
    assert_equal "budget_alerts", notification.kind
    assert_equal "Groceries is over budget", notification.title
    assert_equal "budget:#{Date.current.beginning_of_month}:#{@category.id}", notification.dedupe_key
  end

  test "sweeping repeatedly reports the same fact only once" do
    overspend!
    NotificationSweeper.new(@user).call

    assert_no_difference -> { @user.notifications.count } do
      3.times { NotificationSweeper.new(@user.reload).call }
    end
  end

  test "says nothing while spending is within the allocation" do
    overspend!(4_000)

    assert_no_difference -> { @user.notifications.count } do
      NotificationSweeper.new(@user).call
    end
  end

  test "a disabled preference suppresses delivery" do
    overspend!
    @user.notification_preferences.find_by(key: "budget_alerts").update!(enabled: false)

    assert_no_difference -> { @user.notifications.count } do
      NotificationSweeper.new(@user.reload).call
    end
  end

  test "spending in a category with no allocation is not 'over budget'" do
    unbudgeted = @user.categories.create!(name: "Unplanned", icon: "more-horizontal", color: "#6b7280", category_type: :expense)
    @user.transactions.create!(date: Date.current, amount_cents: 50_000, transaction_type: :expense, category: unbudgeted)

    NotificationSweeper.new(@user).call

    assert_empty @user.notifications.where("title LIKE ?", "%Unplanned%"),
      "category_breakdown reports unbudgeted spend at a nominal 100%; that is not over budget"
  end

  test "reports only the highest goal milestone crossed" do
    goal = @user.savings.goals.create!(name: "Trip", target_cents: 100_000, icon: "plane", color: "#f97316")
    @user.savings.goal_contributions.create!(goal: goal, amount_cents: 80_000)

    NotificationSweeper.new(@user).call
    milestones = @user.notifications.where(kind: "goal_milestones")

    assert_equal 1, milestones.count
    assert_equal "Trip hit 75%", milestones.first.title
  end

  test "a newly crossed milestone still gets through" do
    goal = @user.savings.goals.create!(name: "Trip", target_cents: 100_000, icon: "plane", color: "#f97316")
    @user.savings.goal_contributions.create!(goal: goal, amount_cents: 30_000)
    NotificationSweeper.new(@user).call

    @user.savings.goal_contributions.create!(goal: goal, amount_cents: 30_000)

    assert_difference -> { @user.notifications.where(kind: "goal_milestones").count }, 1 do
      NotificationSweeper.new(@user.reload).call
    end
    assert_equal "Trip hit 50%", @user.notifications.where(kind: "goal_milestones").order(:id).last.title
  end
end

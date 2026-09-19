require "test_helper"

class NotificationPreferenceTest < ActiveSupport::TestCase
  test "a new user is seeded with a row for every catalogue entry" do
    user = User.create!(email: "seeded@example.com", password: "password123")

    assert_equal NotificationPreference::KEYS.sort, user.notification_preferences.pluck(:key).sort
    NotificationPreference::TYPES.each do |key, config|
      assert_equal config[:default], user.notification_preferences.find_by(key: key).enabled, key
    end
  end

  test "keys outside the catalogue are rejected" do
    preference = NotificationPreference.new(user: users(:one), key: "nonsense")

    assert_not preference.valid?
    assert_includes preference.errors[:key], "is not included in the list"
  end

  test "the database refuses a duplicate key for one user" do
    user = User.create!(email: "dupe@example.com", password: "password123")

    assert_raises ActiveRecord::RecordNotUnique do
      NotificationPreference.insert!(
        { user_id: user.id, key: "budget_alerts", enabled: false,
          created_at: Time.current, updated_at: Time.current }
      )
    end
  end

  test "notifies? reports a stored false rather than falling back to the default" do
    user = User.create!(email: "off@example.com", password: "password123")
    user.notification_preferences.find_by(key: "budget_alerts").update!(enabled: false)

    # The catalogue default is true, so a naive `pref&.enabled || default` returns true here.
    assert_equal true, NotificationPreference::TYPES["budget_alerts"][:default]
    assert_equal false, user.reload.notifies?(:budget_alerts)
  end

  test "notifies? falls back to the catalogue when no row exists" do
    # Fixtures insert directly and skip callbacks, so fixture users have no rows —
    # the same shape as a setting added to the catalogue before its backfill runs.
    user = users(:one)
    assert_empty user.notification_preferences

    assert_equal true, user.notifies?(:budget_alerts)
    assert_equal false, user.notifies?(:weekly_summary)
  end

  test "notifies? raises on an unknown key instead of quietly answering no" do
    assert_raises(KeyError) { users(:one).notifies?(:weeky_summary) }
  end

  test "notifies? accepts a symbol or a string" do
    user = User.create!(email: "sym@example.com", password: "password123")

    assert_equal user.notifies?(:budget_alerts), user.notifies?("budget_alerts")
  end
end

require "test_helper"

class PurgeReadNotificationsJobTest < ActiveJob::TestCase
  setup do
    @user = User.create!(email: "purge@example.com", password: "password123")
  end

  def notification(title, age:, read:)
    @user.notifications.create!(kind: "budget_alerts", title: title, created_at: age,
      read_at: read ? age + 1.hour : nil)
  end

  test "deletes read notifications past the retention window" do
    old_read = notification("old read", age: 8.days.ago, read: true)

    assert_difference -> { Notification.count }, -1 do
      PurgeReadNotificationsJob.perform_now
    end
    assert_not Notification.exists?(old_read.id)
  end

  test "keeps read notifications inside the window" do
    recent = notification("recent read", age: 2.days.ago, read: true)

    assert_no_difference -> { Notification.count } do
      PurgeReadNotificationsJob.perform_now
    end
    assert Notification.exists?(recent.id)
  end

  test "never deletes an unread notification, however old" do
    ancient = notification("ancient unread", age: 2.years.ago, read: false)

    assert_no_difference -> { Notification.count } do
      PurgeReadNotificationsJob.perform_now
    end
    assert Notification.exists?(ancient.id)
  end
end

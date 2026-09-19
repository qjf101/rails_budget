require "test_helper"

class WeeklySummaryJobTest < ActiveJob::TestCase
  # ActiveJob::TestCase does not bring in the mailer assertions; ActionMailer::TestCase does.
  include ActionMailer::TestHelper
  setup do
    @wants = User.create!(email: "wants@example.com", password: "password123")
    @wants.notification_preferences.find_by(key: "weekly_summary").update!(enabled: true)

    @declines = User.create!(email: "declines@example.com", password: "password123")
    # left at the catalogue default, which is false
  end

  test "mails only the users whose preference is enabled" do
    assert_enqueued_emails 1 do
      WeeklySummaryJob.perform_now
    end

    assert_enqueued_email_with WeeklySummaryMailer, :summary, args: [@wants, Date.current]
  end

  test "sends nothing once the preference is turned off" do
    @wants.notification_preferences.find_by(key: "weekly_summary").update!(enabled: false)

    assert_no_enqueued_emails do
      WeeklySummaryJob.perform_now
    end
  end
end

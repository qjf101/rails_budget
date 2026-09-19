class WeeklySummaryJob < ApplicationJob
  queue_as :default

  # The preference check lives here rather than in the mailer, so there is exactly
  # one place that decides who gets mail. Because every user is guaranteed a row for
  # every setting (see the CreateNotificationPreferences migration), this is a plain
  # join — no LEFT JOIN with a default duplicated out of the Ruby catalogue.
  def perform(week_ending: Date.current)
    recipients.find_each do |user|
      # deliver_later, not deliver_now: one job per email, so a single bad address
      # retries on its own instead of failing the whole run.
      WeeklySummaryMailer.summary(user, week_ending).deliver_later
    end
  end

  private

  def recipients
    User.joins(:notification_preferences)
        .where(notification_preferences: { key: "weekly_summary", enabled: true })
  end
end

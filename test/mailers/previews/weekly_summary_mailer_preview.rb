# Visit http://localhost:3000/rails/mailers to render these without sending anything.
class WeeklySummaryMailerPreview < ActionMailer::Preview
  def summary
    WeeklySummaryMailer.summary(User.first)
  end

  # The empty state is the one you never see by accident, so it gets its own preview.
  def summary_with_no_activity
    WeeklySummaryMailer.summary(User.first, 5.years.ago.to_date)
  end
end

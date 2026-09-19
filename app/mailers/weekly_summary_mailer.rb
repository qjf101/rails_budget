class WeeklySummaryMailer < ApplicationMailer
  # Deliberately does no preference checking. A mailer's job is to render and send
  # what it was asked to; deciding *who* should receive it belongs to the caller, so
  # the rule lives in one place (the job) rather than being half-enforced here.
  def summary(user, week_ending = Date.current)
    @user = user
    @summary = WeeklySummary.new(user, week_ending)

    mail(
      to: @user.email,
      subject: "Your week in review — #{@summary.range.first.strftime("%b %-d")} to #{@summary.range.last.strftime("%b %-d")}"
    )
  end
end

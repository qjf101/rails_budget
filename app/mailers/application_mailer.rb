class ApplicationMailer < ActionMailer::Base
  default from: %("budget app" <no-reply@budgetapp.test>)
  layout "mailer"
  # Mailer views are a separate view context: unlike controllers, they do not pick
  # up app/helpers automatically, so usd/icon_svg have to be included explicitly.
  helper ApplicationHelper
end

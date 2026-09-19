# Signs visitors in as a shared demo account when DEMO_AUTO_LOGIN is set, so the app
# can be shown off without anyone creating an account.
#
# This bypasses authentication for everyone who can reach the app. Only ever point
# it at an account whose data you are happy for the public to read and change.
module DemoLogin
  # The cookie, not the session: signing out resets the session, so a session flag
  # would be wiped by the very action it needs to outlive.
  SUPPRESSION_COOKIE = :skip_demo_auto_login
  SUPPRESSION_WINDOW = 1.day

  def self.enabled?
    ActiveModel::Type::Boolean.new.cast(ENV["DEMO_AUTO_LOGIN"]).present?
  end

  def self.email
    ENV.fetch("DEMO_USER_EMAIL", "demo@example.com")
  end

  # True only when the shared account is in use *and* the feature is on, so the
  # banner never appears for someone signed into their own account.
  def self.demo_user?(user)
    enabled? && user.present? && user.email == email
  end

  # nil rather than raising: a missing demo account should degrade to the normal
  # sign-in page, not take the whole app down.
  def self.user
    User.find_by(email: email) if enabled?
  end
end

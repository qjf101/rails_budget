# Puts the shared demo account back to its seeded state, so visitors' edits do not
# accumulate. Only ever touches the account named by DEMO_USER_EMAIL.
class ResetDemoDataJob < ApplicationJob
  queue_as :default

  def perform
    # Guarded twice: without the feature on there is no shared account to reset, and
    # this job must never be able to wipe a real user's data by misconfiguration.
    return unless DemoLogin.enabled?

    user = User.find_by(email: DemoLogin.email)
    # Destroying the user cascades through categories, transactions, budgets,
    # savings, goals and notifications, which is why a plain re-seed is not enough:
    # re-seeding alone would leave anything a visitor added behind.
    user&.destroy

    # Recreates the account at the same email, so DemoLogin finds it again. Visitors
    # holding an old session are signed out and auto-signed back in on their next request.
    load Rails.root.join("db/seeds.rb")
  end
end

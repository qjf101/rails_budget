class ApplicationController < ActionController::Base
  # Declared first so it runs before authenticate_user! gets a chance to redirect.
  before_action :demo_auto_login, if: -> { DemoLogin.enabled? }
  before_action :authenticate_user!, unless: :devise_controller?
  layout :layout_by_resource
  helper_method :unread_notifications_count, :viewing_demo?

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private

  # Devise's own pages (sign in, sign up, password reset) have no signed-in user yet,
  # so they can't render the authenticated shell's sidebar (which reads current_user).
  def layout_by_resource
    devise_controller? ? "devise" : "application"
  end

  def viewing_demo?
    DemoLogin.demo_user?(current_user)
  end

  # Opt-in via DEMO_AUTO_LOGIN. Deliberately skips Devise's own controllers, so the
  # sign-in page stays reachable and anyone can still sign in as themselves.
  def demo_auto_login
    return if devise_controller?
    return if user_signed_in?
    return if cookies[DemoLogin::SUPPRESSION_COOKIE].present?

    demo_user = DemoLogin.user
    sign_in(demo_user) if demo_user
  end

  # Call after anything that can change budget or goal standing. Any write path
  # that forgets this silently produces no notifications — the cost of an explicit
  # call site over a model callback that would also fire during seeding.
  def sweep_notifications
    NotificationSweeper.new(current_user).call
  end

  # Runs on every page because the bell lives in the layout. Memoised so a render
  # that touches it twice still costs one query, and backed by a partial index.
  def unread_notifications_count
    return 0 unless user_signed_in?

    @unread_notifications_count ||= current_user.notifications.unread.count
  end
end

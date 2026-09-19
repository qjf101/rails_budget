class NotificationsController < ApplicationController
  LIMIT = 20

  # Rendered into a lazy turbo frame, so this only runs when the bell is opened.
  # Opening the bell is what marks things read: routing each click through a
  # redirect made Turbo re-render the destination and killed any <canvas> on it.
  def index
    @notifications = current_user.notifications.recent.limit(LIMIT).to_a

    # Every unread row, not just the ones on screen: scoping this to the rendered
    # page left the badge showing a count the user had no way to clear.
    # update_all deliberately does not touch the objects already loaded above, so
    # this render still shows them as unread. They read as "new" once, then settle.
    current_user.notifications.unread.update_all(read_at: Time.current)

    render partial: "notifications/menu", locals: { notifications: @notifications }
  end

  # Kept for links arriving from outside the app (emails), where a redirect costs
  # nothing because it is a fresh document load rather than a Turbo visit.
  def show
    notification = current_user.notifications.find(params[:id])
    notification.mark_read!
    redirect_to(notification.url.presence || root_path, allow_other_host: false)
  end
end

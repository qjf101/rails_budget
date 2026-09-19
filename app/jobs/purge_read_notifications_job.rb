class PurgeReadNotificationsJob < ApplicationJob
  queue_as :default

  RETENTION = 1.week

  # Only read rows are ever removed: nothing should disappear before it has been
  # seen. Unread notifications are kept indefinitely by design.
  def perform
    # delete_all, not destroy_all: one DELETE instead of N object loads plus N
    # DELETEs, and Notification has no callbacks or dependents that need running.
    Notification.where.not(read_at: nil)
                .where(created_at: ...RETENTION.ago)
                .delete_all
  end
end

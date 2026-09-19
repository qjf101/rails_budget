class Notification < ApplicationRecord
  belongs_to :user

  # kind is deliberately the same vocabulary as the preference catalogue: it is how
  # an emitter asks "is this user still listening for this?" before creating a row.
  validates :kind, inclusion: { in: NotificationPreference::KEYS }
  validates :title, presence: true

  scope :unread, -> { where(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }

  # The single door notifications come through. Returns nil when the user has the
  # preference off, or when this fact has already been reported.
  def self.deliver(user:, kind:, title:, body: nil, url: nil, dedupe_key: nil)
    return nil unless user.notifies?(kind)

    user.notifications.create!(kind: kind, title: title, body: body, url: url, dedupe_key: dedupe_key)
  rescue ActiveRecord::RecordNotUnique
    # Lost the race, or already delivered. Either way there is nothing to do.
    nil
  end

  def read? = read_at.present?

  def mark_read!
    update!(read_at: Time.current) unless read?
  end
end

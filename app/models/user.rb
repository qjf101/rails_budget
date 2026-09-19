class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable

  # Rendered through a 200x200 variant (see shared/_avatar), processed by libvips.
  has_one_attached :avatar

  has_many :notifications, dependent: :destroy
  has_many :notification_preferences, dependent: :destroy
  # Lets the settings form submit the whole set in one request. No allow_destroy
  # and no reject_if: the rows are fixed, only :enabled ever changes.
  accepts_nested_attributes_for :notification_preferences
  has_many :categories, dependent: :destroy
  has_many :budgets, dependent: :destroy
  has_many :transactions, dependent: :destroy
  has_one :savings, dependent: :destroy

  validate :avatar_is_a_reasonable_image

  after_create :create_savings!
  after_create :seed_notification_preferences

  def initial
    (name.presence || email).to_s.strip[0].to_s.upcase
  end

  # Reads from the loaded association so checking several settings in a row costs
  # one query. Falls back to the catalogue default if a row is somehow missing.
  def notifies?(key)
    preference = notification_preferences.detect { |p| p.key == key.to_s }
    return preference.enabled unless preference.nil?

    NotificationPreference::TYPES.fetch(key.to_s).fetch(:default)
  end

  private

  def seed_notification_preferences
    NotificationPreference::TYPES.each do |key, config|
      notification_preferences.create!(key: key, enabled: config[:default])
    end
  end

  def avatar_is_a_reasonable_image
    return unless avatar.attached?

    unless avatar.content_type.in?(%w[image/jpeg image/png image/webp])
      errors.add(:avatar, "must be a JPG, PNG or WebP")
    end

    errors.add(:avatar, "must be smaller than 5MB") if avatar.byte_size > 5.megabytes
  end
end

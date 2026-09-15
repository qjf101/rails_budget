class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable

  # Rendered through a 200x200 variant (see shared/_avatar), processed by libvips.
  has_one_attached :avatar

  has_many :categories, dependent: :destroy
  has_many :budgets, dependent: :destroy
  has_many :transactions, dependent: :destroy
  has_one :savings, dependent: :destroy

  validate :avatar_is_a_reasonable_image

  after_create :create_savings!

  def initial
    (name.presence || email).to_s.strip[0].to_s.upcase
  end

  private

  def avatar_is_a_reasonable_image
    return unless avatar.attached?

    unless avatar.content_type.in?(%w[image/jpeg image/png image/webp])
      errors.add(:avatar, "must be a JPG, PNG or WebP")
    end

    errors.add(:avatar, "must be smaller than 5MB") if avatar.byte_size > 5.megabytes
  end
end

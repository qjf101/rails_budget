module Iconable
  extend ActiveSupport::Concern

  ICON_KEYS = %w[
    home utensils car shopping-bag film file-text piggy-bank dollar-sign
    more-horizontal plane heart book briefcase dumbbell paw phone gift
    coffee graduation-cap wrench credit-card umbrella camera music tree baby target star
  ].freeze

  included do
    validates :icon, inclusion: { in: ICON_KEYS }, allow_nil: true
  end
end

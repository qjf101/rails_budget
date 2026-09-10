class Goal < ApplicationRecord
  belongs_to :user
  validates :name, :target_cents, presence: true

  def percent_complete
    return 0 if target_cents.to_i.zero?
    ((current_cents.to_f / target_cents) * 100).round
  end
end
class NotificationPreference < ApplicationRecord
  # The catalogue lives in code, not in the table. A row-per-setting table records
  # what a user decided; it can't tell you which settings exist — only which ones
  # someone has an opinion about. Adding a toggle means adding an entry here.
  TYPES = {
    "budget_alerts" => {
      title: "Budget alerts",
      description: "Get notified when a category goes over budget",
      default: true,
    },
    "goal_milestones" => {
      title: "Goal milestones",
      description: "Celebrate when you hit 25%, 50%, 75%, and 100% of a goal",
      default: true,
    },
    "weekly_summary" => {
      title: "Weekly summary email",
      description: "A recap of income, spending, and progress every Monday",
      default: false,
    },
  }.freeze

  KEYS = TYPES.keys.freeze

  belongs_to :user

  validates :key, inclusion: { in: KEYS }, uniqueness: { scope: :user_id }

  scope :enabled, -> { where(enabled: true) }

  def title = TYPES.fetch(key)[:title]
  def description = TYPES.fetch(key)[:description]
end

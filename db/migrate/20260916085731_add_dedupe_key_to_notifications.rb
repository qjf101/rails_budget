class AddDedupeKeyToNotifications < ActiveRecord::Migration[8.1]
  def change
    add_column :notifications, :dedupe_key, :string

    # Describes a *fact* ("Entertainment is over its September budget"), not an
    # event, so re-running the sweep can't notify twice. NULL is allowed and never
    # collides, which leaves room for one-off notifications that shouldn't dedupe.
    add_index :notifications, [:user_id, :dedupe_key], unique: true, where: "dedupe_key IS NOT NULL"
  end
end

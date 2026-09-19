class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.string :kind, null: false
      t.string :title, null: false
      t.string :body
      t.string :url
      # A timestamp rather than a boolean: same information plus *when*, and no way
      # to end up with read=true / read_at=nil contradicting each other.
      t.datetime :read_at
      t.timestamps
    end

    # Drives the dropdown list.
    add_index :notifications, [ :user_id, :created_at ]

    # Drives the unread badge, which runs on every page load. A partial index only
    # holds the unread rows, so it stays small however much history accumulates.
    add_index :notifications, :user_id, where: "read_at IS NULL", name: "index_notifications_unread"
  end
end

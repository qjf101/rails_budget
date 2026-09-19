class CreateNotificationPreferences < ActiveRecord::Migration[8.1]
  def up
    create_table :notification_preferences do |t|
      t.references :user, null: false, foreign_key: true
      t.string :key, null: false
      t.boolean :enabled, null: false, default: true
      t.timestamps
    end

    # A validation can't stop two concurrent requests writing the same user+key;
    # this index is what actually enforces one row per setting per user.
    add_index :notification_preferences, [:user_id, :key], unique: true

    # Every user gets a full set of rows, so "who wants the weekly summary?" stays
    # a plain join instead of a LEFT JOIN with a Ruby-side default.
    User.reset_column_information
    User.find_each do |user|
      NotificationPreference::TYPES.each do |key, config|
        NotificationPreference.create!(user: user, key: key, enabled: config[:default])
      end
    end
  end

  def down
    drop_table :notification_preferences
  end
end

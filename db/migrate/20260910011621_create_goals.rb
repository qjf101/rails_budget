class CreateGoals < ActiveRecord::Migration[8.1]
  def change
    create_table :goals do |t|
      t.references :savings, null: false, foreign_key: true
      t.string :name
      t.integer :target_cents
      t.date :target_date
      t.string :icon
      t.datetime :completed_at

      t.timestamps
    end
  end
end

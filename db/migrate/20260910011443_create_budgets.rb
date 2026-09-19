class CreateBudgets < ActiveRecord::Migration[8.1]
  def change
    create_table :budgets do |t|
      t.references :user, null: false, foreign_key: true
      t.date :month
      t.integer :income_cents

      t.timestamps
    end

    add_index :budgets, [ :user_id, :month ], unique: true
  end
end

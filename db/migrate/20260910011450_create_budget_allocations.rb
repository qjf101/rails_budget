class CreateBudgetAllocations < ActiveRecord::Migration[8.1]
  def change
    create_table :budget_allocations do |t|
      t.references :budget, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.integer :amount_cents

      t.timestamps
    end

    add_index :budget_allocations, [ :budget_id, :category_id ], unique: true
  end
end

class CreateGoalContributions < ActiveRecord::Migration[8.1]
  def change
    create_table :goal_contributions do |t|
      t.references :savings, null: false, foreign_key: true
      t.references :goal, foreign_key: true   # nullable — absent means unallocated/general savings
      t.bigint :transaction_id                # nullable — absent means a manual entry, not sourced from a Transaction
      t.integer :amount_cents
      t.string :note
      t.date :contributed_at

      t.timestamps
    end

    add_index :goal_contributions, :transaction_id
    add_foreign_key :goal_contributions, :transactions, column: :transaction_id
  end
end

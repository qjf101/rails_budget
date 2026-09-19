class CreateTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :transactions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :category, foreign_key: true
      t.date :date
      t.integer :amount_cents
      t.string :transaction_type
      t.string :description
      t.text :notes
      t.string :source
      t.string :external_id

      t.timestamps
    end

    change_column_default :transactions, :source, from: nil, to: "manual"
    add_index :transactions, [ :user_id, :external_id ], unique: true, where: "external_id IS NOT NULL"
  end
end

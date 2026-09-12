# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_12_183931) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "budget_allocations", force: :cascade do |t|
    t.integer "amount_cents"
    t.bigint "budget_id", null: false
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["budget_id", "category_id"], name: "index_budget_allocations_on_budget_id_and_category_id", unique: true
    t.index ["budget_id"], name: "index_budget_allocations_on_budget_id"
    t.index ["category_id"], name: "index_budget_allocations_on_category_id"
  end

  create_table "budgets", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "income_cents"
    t.date "month"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "month"], name: "index_budgets_on_user_id_and_month", unique: true
    t.index ["user_id"], name: "index_budgets_on_user_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "category_type"
    t.string "color"
    t.datetime "created_at", null: false
    t.string "icon"
    t.string "name"
    t.integer "position"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_categories_on_user_id"
  end

  create_table "goal_contributions", force: :cascade do |t|
    t.integer "amount_cents"
    t.date "contributed_at"
    t.datetime "created_at", null: false
    t.bigint "goal_id"
    t.string "note"
    t.bigint "savings_id", null: false
    t.bigint "transaction_id"
    t.datetime "updated_at", null: false
    t.index ["goal_id"], name: "index_goal_contributions_on_goal_id"
    t.index ["savings_id"], name: "index_goal_contributions_on_savings_id"
    t.index ["transaction_id"], name: "index_goal_contributions_on_transaction_id"
  end

  create_table "goals", force: :cascade do |t|
    t.string "color"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.string "icon"
    t.string "name"
    t.bigint "savings_id", null: false
    t.integer "target_cents"
    t.date "target_date"
    t.datetime "updated_at", null: false
    t.index ["savings_id"], name: "index_goals_on_savings_id"
  end

  create_table "savings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_savings_on_user_id", unique: true
  end

  create_table "transactions", force: :cascade do |t|
    t.integer "amount_cents"
    t.bigint "category_id"
    t.datetime "created_at", null: false
    t.date "date"
    t.string "description"
    t.string "external_id"
    t.text "notes"
    t.string "source", default: "manual"
    t.string "transaction_type"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["category_id"], name: "index_transactions_on_category_id"
    t.index ["user_id", "external_id"], name: "index_transactions_on_user_id_and_external_id", unique: true, where: "(external_id IS NOT NULL)"
    t.index ["user_id"], name: "index_transactions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "budget_allocations", "budgets"
  add_foreign_key "budget_allocations", "categories"
  add_foreign_key "budgets", "users"
  add_foreign_key "categories", "users"
  add_foreign_key "goal_contributions", "goals"
  add_foreign_key "goal_contributions", "savings", column: "savings_id"
  add_foreign_key "goal_contributions", "transactions"
  add_foreign_key "goals", "savings", column: "savings_id"
  add_foreign_key "savings", "users"
  add_foreign_key "transactions", "categories"
  add_foreign_key "transactions", "users"
end

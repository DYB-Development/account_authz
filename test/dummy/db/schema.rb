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

ActiveRecord::Schema[8.1].define(version: 2026_09_16_000001) do
  create_table "citizen_assignments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "member_id", null: false
    t.string "member_type", null: false
    t.integer "role_id", null: false
    t.datetime "updated_at", null: false
    t.index ["member_type", "member_id", "role_id"], name: "index_citizen_assignments_unique", unique: true
    t.index ["member_type", "member_id"], name: "index_citizen_assignments_on_member"
    t.index ["role_id"], name: "index_citizen_assignments_on_role_id"
  end

  create_table "citizen_roles", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.json "capabilities", default: [], null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "rank", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_citizen_roles_on_account_id"
  end

  create_table "members", force: :cascade do |t|
    t.bigint "account_id"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name"
    t.datetime "updated_at", null: false
  end
end

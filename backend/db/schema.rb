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

ActiveRecord::Schema[8.1].define(version: 2026_07_08_003451) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "admin_users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_admin_users_on_email_address", unique: true
  end

  create_table "event_participants", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "event_id", null: false
    t.bigint "partcipant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id", "partcipant_id"], name: "index_event_participants_on_event_id_and_partcipant_id", unique: true
    t.index ["event_id"], name: "index_event_participants_on_event_id"
    t.index ["partcipant_id"], name: "index_event_participants_on_partcipant_id"
  end

  create_table "events", force: :cascade do |t|
    t.boolean "closed", default: false, null: false
    t.datetime "created_at", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["title"], name: "index_events_on_title", unique: true
  end

  create_table "partcipants", force: :cascade do |t|
    t.string "avatar", null: false
    t.datetime "created_at", null: false
    t.boolean "eliminated", default: false, null: false
    t.string "nickname", null: false
    t.datetime "updated_at", null: false
    t.index ["nickname"], name: "index_partcipants_on_nickname", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "admin_user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.string "ip_address"
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.index ["admin_user_id"], name: "index_sessions_on_admin_user_id"
    t.index ["token"], name: "index_sessions_on_token", unique: true
  end

  create_table "votes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.bigint "event_id", null: false
    t.bigint "partcipant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_votes_on_email"
    t.index ["event_id"], name: "index_votes_on_event_id"
    t.index ["partcipant_id"], name: "index_votes_on_partcipant_id"
  end

  add_foreign_key "event_participants", "events"
  add_foreign_key "event_participants", "partcipants"
  add_foreign_key "sessions", "admin_users"
  add_foreign_key "votes", "events"
  add_foreign_key "votes", "partcipants"
end

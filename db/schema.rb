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

ActiveRecord::Schema[8.1].define(version: 2026_02_12_060234) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "apple_webhook_events", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.string "currency"
    t.text "error_message"
    t.string "event_type", null: false
    t.datetime "expires_date"
    t.string "notification_uuid", null: false
    t.string "processing_status", default: "pending", null: false
    t.string "product_id"
    t.datetime "purchase_date"
    t.jsonb "raw_payload"
    t.string "transaction_id", null: false
    t.datetime "updated_at", null: false
    t.index ["notification_uuid"], name: "index_apple_webhook_events_on_notification_uuid", unique: true
    t.index ["processing_status"], name: "index_apple_webhook_events_on_processing_status"
    t.index ["transaction_id"], name: "index_apple_webhook_events_on_transaction_id"
  end

  create_table "subscription_periods", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.string "currency"
    t.datetime "ends_at", null: false
    t.string "event_type", null: false
    t.datetime "starts_at", null: false
    t.bigint "subscription_id", null: false
    t.datetime "updated_at", null: false
    t.index ["subscription_id", "starts_at"], name: "index_subscription_periods_on_subscription_id_and_starts_at"
    t.index ["subscription_id"], name: "index_subscription_periods_on_subscription_id"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.datetime "cancelled_at"
    t.datetime "created_at", null: false
    t.datetime "current_period_end"
    t.datetime "current_period_start"
    t.string "product_id", null: false
    t.string "status", default: "provisional", null: false
    t.string "transaction_id", null: false
    t.datetime "updated_at", null: false
    t.string "user_id", null: false
    t.index ["status"], name: "index_subscriptions_on_status"
    t.index ["transaction_id"], name: "index_subscriptions_on_transaction_id", unique: true
    t.index ["user_id", "status"], name: "index_subscriptions_on_user_id_and_status"
    t.index ["user_id"], name: "index_subscriptions_on_user_id"
  end

  add_foreign_key "subscription_periods", "subscriptions"
end

# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2023_06_05_095701) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "auth_providers", force: :cascade do |t|
    t.bigint "user_id"
    t.integer "auth_provider"
    t.jsonb "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_auth_providers_on_user_id"
  end

  create_table "categories", force: :cascade do |t|
    t.bigint "parent_id"
    t.string "name"
    t.integer "level"
    t.string "image_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_categories_on_name", unique: true
    t.index ["parent_id"], name: "index_categories_on_parent_id"
  end

  create_table "categorizations", force: :cascade do |t|
    t.bigint "course_id"
    t.bigint "category_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_categorizations_on_category_id"
    t.index ["course_id"], name: "index_categorizations_on_course_id"
  end

  create_table "courses", force: :cascade do |t|
    t.bigint "creator_id"
    t.string "title"
    t.integer "sale_status", default: 1
    t.decimal "price", precision: 10, scale: 2
    t.string "currency"
    t.boolean "private", default: false
    t.boolean "test", default: false
    t.text "about"
    t.integer "version", default: 0
    t.datetime "test_expiration"
    t.integer "publish_status", default: 1
    t.integer "course_status", default: 1
    t.integer "next_edition"
    t.integer "previous_edition"
    t.float "rating", default: 0.0
    t.jsonb "instructions"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "question_tags"
    t.datetime "last_publish_date"
    t.integer "rating_count", default: 0
    t.index ["creator_id"], name: "index_courses_on_creator_id"
    t.index ["title"], name: "index_courses_on_title"
  end

  create_table "financial_cards", force: :cascade do |t|
    t.string "country"
    t.string "expiry"
    t.string "first_six"
    t.string "issuer"
    t.string "last_four"
    t.string "card_type"
    t.string "token"
    t.string "provider"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token"], name: "index_financial_cards_on_token", unique: true
    t.index ["user_id"], name: "index_financial_cards_on_user_id"
  end

  create_table "guests", force: :cascade do |t|
    t.string "email"
    t.jsonb "result"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_guests_on_email", unique: true
  end

  create_table "interests", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "category_id"
    t.integer "affinity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_interests_on_category_id"
    t.index ["user_id"], name: "index_interests_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "user_id"
    t.text "content"
    t.integer "category"
    t.boolean "read"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "otps", force: :cascade do |t|
    t.string "user_identity"
    t.string "otp"
    t.integer "auth_type"
    t.integer "tries"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_identity"], name: "index_otps_on_user_identity", unique: true
  end

  create_table "questions", force: :cascade do |t|
    t.bigint "course_id"
    t.integer "order"
    t.text "question"
    t.jsonb "tags"
    t.jsonb "options"
    t.boolean "multi_answer", default: false
    t.integer "multiplier", default: 1
    t.text "explanation"
    t.integer "version", default: 0
    t.integer "publish_status", default: 1
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "answer"
    t.jsonb "question_raw"
    t.jsonb "explanation_raw"
    t.integer "question_status", default: 1
    t.jsonb "draft"
    t.bigint "previous_id"
    t.bigint "next_id"
    t.string "year"
    t.bigint "creator_id"
    t.jsonb "notes"
    t.index ["course_id"], name: "index_questions_on_course_id"
    t.index ["creator_id"], name: "index_questions_on_creator_id"
  end

  create_table "refresh_tokens", force: :cascade do |t|
    t.string "token"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_refresh_tokens_on_user_id", unique: true
  end

  create_table "results", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "course_id"
    t.integer "score"
    t.integer "total"
    t.bigint "duration"
    t.integer "session_type"
    t.string "extra_id"
    t.jsonb "session_items"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "elapsed_time"
    t.jsonb "tags"
    t.string "session_key"
    t.integer "num_questions"
    t.index ["course_id"], name: "index_results_on_course_id"
    t.index ["session_key"], name: "index_results_on_session_key", unique: true
    t.index ["user_id"], name: "index_results_on_user_id"
  end

  create_table "reviews", force: :cascade do |t|
    t.bigint "course_id"
    t.bigint "user_id"
    t.integer "rating"
    t.text "review"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_reviews_on_course_id"
    t.index ["user_id"], name: "index_reviews_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "course_id"
    t.string "extra_id"
    t.bigint "duration"
    t.integer "current_question_number", default: 1
    t.integer "session_type"
    t.string "device_id"
    t.string "web_tab_id"
    t.jsonb "session_items"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_sessions_on_course_id"
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.bigint "buyer_id"
    t.bigint "purchase_item_id"
    t.integer "purchase_item_type"
    t.string "purchase_currency"
    t.decimal "purchase_price", precision: 10, scale: 2
    t.integer "transaction_status"
    t.integer "payment_method"
    t.string "description"
    t.string "external_txn_id"
    t.datetime "completed_at"
    t.jsonb "extra"
    t.string "transaction_ref"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["buyer_id"], name: "index_transactions_on_buyer_id"
    t.index ["transaction_ref"], name: "index_transactions_on_transaction_ref", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "username"
    t.string "password_digest"
    t.string "first_name"
    t.string "last_name"
    t.string "other_name"
    t.string "email"
    t.date "date_of_birth"
    t.boolean "creator"
    t.integer "user_status", default: 1
    t.string "occupation"
    t.string "country"
    t.boolean "pro_account"
    t.text "about"
    t.boolean "certified"
    t.jsonb "preferences"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "onboarding", default: {}
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "auth_providers", "users"
  add_foreign_key "categories", "categories", column: "parent_id"
  add_foreign_key "categorizations", "categories"
  add_foreign_key "categorizations", "courses"
  add_foreign_key "courses", "users", column: "creator_id"
  add_foreign_key "financial_cards", "users"
  add_foreign_key "interests", "categories"
  add_foreign_key "interests", "users"
  add_foreign_key "notifications", "users"
  add_foreign_key "questions", "courses"
  add_foreign_key "questions", "questions", column: "next_id"
  add_foreign_key "questions", "questions", column: "previous_id"
  add_foreign_key "questions", "users", column: "creator_id"
  add_foreign_key "refresh_tokens", "users"
  add_foreign_key "results", "courses"
  add_foreign_key "results", "users"
  add_foreign_key "reviews", "courses"
  add_foreign_key "reviews", "users"
  add_foreign_key "sessions", "courses"
  add_foreign_key "sessions", "users"
  add_foreign_key "transactions", "users", column: "buyer_id"
end

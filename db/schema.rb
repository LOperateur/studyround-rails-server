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

ActiveRecord::Schema.define(version: 2022_05_09_120328) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

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
    t.integer "sale_status"
    t.decimal "price", precision: 10, scale: 2
    t.string "currency"
    t.boolean "private"
    t.boolean "test"
    t.text "about"
    t.string "image_url"
    t.integer "version", default: 1
    t.datetime "test_expiration"
    t.integer "publish_status"
    t.jsonb "draft_content"
    t.integer "course_status"
    t.integer "next_edition"
    t.integer "previous_edition"
    t.float "rating"
    t.jsonb "instructions"
    t.boolean "completed"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "question_tags"
    t.index ["creator_id"], name: "index_courses_on_creator_id"
    t.index ["title"], name: "index_courses_on_title"
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
    t.string "question_image_url"
    t.jsonb "options"
    t.string "answer_image_url"
    t.boolean "multi_answer", default: false
    t.integer "multiplier", default: 1
    t.text "explanation"
    t.string "explanation_image_url"
    t.integer "version", default: 1
    t.integer "publish_status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "answer"
    t.index ["course_id"], name: "index_questions_on_course_id"
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
    t.bigint "elapsed_time"
    t.bigint "duration"
    t.integer "session_type"
    t.string "extra_id"
    t.jsonb "session_items"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_results_on_course_id"
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

  create_table "users", force: :cascade do |t|
    t.string "username"
    t.string "password_digest"
    t.string "first_name"
    t.string "last_name"
    t.string "other_name"
    t.string "email"
    t.date "date_of_birth"
    t.boolean "creator"
    t.integer "status"
    t.string "occupation"
    t.string "country"
    t.boolean "pro_account"
    t.string "profile_image_url"
    t.text "about"
    t.boolean "certified"
    t.jsonb "preferences"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "categories", "categories", column: "parent_id"
  add_foreign_key "categorizations", "categories"
  add_foreign_key "categorizations", "courses"
  add_foreign_key "courses", "users", column: "creator_id"
  add_foreign_key "interests", "categories"
  add_foreign_key "interests", "users"
  add_foreign_key "questions", "courses"
  add_foreign_key "refresh_tokens", "users"
  add_foreign_key "results", "courses"
  add_foreign_key "results", "users"
  add_foreign_key "reviews", "courses"
  add_foreign_key "reviews", "users"
end

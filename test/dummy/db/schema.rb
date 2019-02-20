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

ActiveRecord::Schema.define(version: 2019_02_20_151000) do

  create_table "blogs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "blogs_posts", id: false, force: :cascade do |t|
    t.integer "blog_id"
    t.integer "post_id"
    t.index ["blog_id"], name: "index_blogs_posts_on_blog_id"
    t.index ["post_id"], name: "index_blogs_posts_on_post_id"
  end

  create_table "comments", force: :cascade do |t|
    t.integer "post_id"
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "draft_author_type"
    t.integer "draft_author_id"
    t.integer "draft_master_id"
    t.integer "user_id"
    t.index ["draft_author_type", "draft_author_id"], name: "index_comments_on_draft_author_type_and_draft_author_id"
    t.index ["draft_master_id"], name: "index_comments_on_draft_master_id"
    t.index ["post_id"], name: "index_comments_on_post_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "footers", force: :cascade do |t|
    t.text "content"
    t.integer "post_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id"], name: "index_footers_on_post_id"
  end

  create_table "headers", force: :cascade do |t|
    t.text "content"
    t.integer "post_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "draft_author_type"
    t.integer "draft_author_id"
    t.integer "draft_master_id"
    t.index ["draft_author_type", "draft_author_id"], name: "index_headers_on_draft_author_type_and_draft_author_id"
    t.index ["draft_master_id"], name: "index_headers_on_draft_master_id"
    t.index ["post_id"], name: "index_headers_on_post_id"
  end

  create_table "photos", force: :cascade do |t|
    t.integer "post_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id"], name: "index_photos_on_post_id"
  end

  create_table "posts", force: :cascade do |t|
    t.string "title"
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "draft_author_type"
    t.integer "draft_author_id"
    t.integer "draft_master_id"
    t.index ["draft_author_type", "draft_author_id"], name: "index_posts_on_draft_author_type_and_draft_author_id"
    t.index ["draft_master_id"], name: "index_posts_on_draft_master_id"
  end

  create_table "posts_tags", id: false, force: :cascade do |t|
    t.integer "post_id"
    t.integer "tag_id"
    t.index ["post_id"], name: "index_posts_tags_on_post_id"
    t.index ["tag_id"], name: "index_posts_tags_on_tag_id"
  end

  create_table "sample_models", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tags", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "draft_author_type"
    t.integer "draft_author_id"
    t.integer "draft_master_id"
    t.index ["draft_author_type", "draft_author_id"], name: "index_tags_on_draft_author_type_and_draft_author_id"
    t.index ["draft_master_id"], name: "index_tags_on_draft_master_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end

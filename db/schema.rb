# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20170201032320) do

  create_table "comments", force: :cascade do |t|
    t.integer  "user_id",         limit: 4, null: false
    t.integer  "sprint_state_id", limit: 4, null: false
    t.integer  "comment_id",      limit: 4
    t.integer  "resource_id",     limit: 4
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "comments", ["resource_id"], name: "fk_rails_30653fd404", using: :btree
  add_index "comments", ["sprint_state_id"], name: "index_comments_on_sprint_state_id", using: :btree
  add_index "comments", ["user_id"], name: "index_comments_on_user_id", using: :btree

  create_table "contributors", force: :cascade do |t|
    t.integer  "user_id",        limit: 4,   null: false
    t.integer  "sprint_id",      limit: 4,   null: false
    t.string   "repo",           limit: 255, null: false
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.string   "commit",         limit: 255
    t.string   "commit_remote",  limit: 255
    t.boolean  "commit_success"
    t.integer  "insertions",     limit: 4
    t.integer  "deletions",      limit: 4
    t.integer  "lines",          limit: 4
    t.integer  "files",          limit: 4
  end

  add_index "contributors", ["sprint_id"], name: "index_contributors_on_sprint_id", using: :btree
  add_index "contributors", ["user_id"], name: "fk_rails_75adfa0433", using: :btree

  create_table "labels", force: :cascade do |t|
    t.string   "name",       limit: 255, null: false
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "logins", force: :cascade do |t|
    t.integer  "user_id",    limit: 4,   null: false
    t.string   "ip",         limit: 255, null: false
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "logins", ["ip"], name: "index_logins_on_ip", using: :btree
  add_index "logins", ["user_id"], name: "index_logins_on_user", using: :btree

  create_table "projects", force: :cascade do |t|
    t.string   "org",        limit: 255, null: false
    t.string   "name",       limit: 255, null: false
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "resources", force: :cascade do |t|
    t.integer  "sprint_state_id", limit: 4,     null: false
    t.integer  "user_id",         limit: 4,     null: false
    t.integer  "sprint_id",       limit: 4,     null: false
    t.text     "solution",        limit: 65535
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
  end

  add_index "resources", ["sprint_id"], name: "index_resources_on_sprint_id", using: :btree
  add_index "resources", ["sprint_state_id"], name: "index_resources_on_sprint_state_id", using: :btree
  add_index "resources", ["user_id"], name: "index_resources_on_user_id", using: :btree

  create_table "roles", force: :cascade do |t|
    t.string   "name",       limit: 255, null: false
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "skillsets", force: :cascade do |t|
    t.string   "name",       limit: 255, null: false
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "sprint_skillsets", force: :cascade do |t|
    t.integer  "skillset_id", limit: 4,                null: false
    t.integer  "sprint_id",   limit: 4,                null: false
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
    t.boolean  "active",                default: true, null: false
  end

  add_index "sprint_skillsets", ["skillset_id"], name: "index_sprint_skillsets_on_skillset_id", using: :btree
  add_index "sprint_skillsets", ["sprint_id"], name: "index_sprint_skillsets_on_sprint_id", using: :btree

  create_table "sprint_states", force: :cascade do |t|
    t.integer  "sprint_id",  limit: 4, null: false
    t.integer  "state_id",   limit: 4, null: false
    t.datetime "deadline"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.integer  "user_id",    limit: 4
  end

  add_index "sprint_states", ["sprint_id"], name: "index_sprint_states_on_sprint_id", using: :btree
  add_index "sprint_states", ["state_id"], name: "fk_rails_bececa531a", using: :btree

  create_table "sprint_timelines", force: :cascade do |t|
    t.integer  "sprint_id",       limit: 4, null: false
    t.integer  "state_id",        limit: 4
    t.integer  "label_id",        limit: 4
    t.datetime "created_at",                null: false
    t.integer  "project_id",      limit: 4, null: false
    t.integer  "user_id",         limit: 4, null: false
    t.integer  "after",           limit: 4
    t.integer  "comment_id",      limit: 4
    t.integer  "sprint_state_id", limit: 4
  end

  add_index "sprint_timelines", ["comment_id"], name: "fk_rails_1251c5b8fd", using: :btree
  add_index "sprint_timelines", ["label_id"], name: "fk_rails_1b320ef958", using: :btree
  add_index "sprint_timelines", ["sprint_id"], name: "index_sprint_timelines_on_sprint_id", using: :btree
  add_index "sprint_timelines", ["sprint_state_id"], name: "fk_rails_e755d52f56", using: :btree
  add_index "sprint_timelines", ["state_id"], name: "fk_rails_c9feeeb84f", using: :btree

  create_table "sprints", force: :cascade do |t|
    t.integer  "user_id",     limit: 4,     null: false
    t.integer  "project_id",  limit: 4,     null: false
    t.string   "title",       limit: 255
    t.text     "description", limit: 65535
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.datetime "deadline"
    t.string   "sha",         limit: 255
  end

  add_index "sprints", ["project_id"], name: "index_sprints_on_project_id", using: :btree
  add_index "sprints", ["user_id"], name: "index_sprints_on_user_id", using: :btree

  create_table "states", force: :cascade do |t|
    t.string   "name",       limit: 255, null: false
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "user_roles", force: :cascade do |t|
    t.integer  "user_id",    limit: 4,                 null: false
    t.integer  "role_id",    limit: 4,                 null: false
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
    t.boolean  "active",               default: false
  end

  add_index "user_roles", ["role_id"], name: "fk_rails_3369e0d5fc", using: :btree
  add_index "user_roles", ["user_id"], name: "index_user_roles_on_user", using: :btree

  create_table "user_skillsets", force: :cascade do |t|
    t.integer  "user_id",     limit: 4,                null: false
    t.integer  "skillset_id", limit: 4,                null: false
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
    t.boolean  "active",                default: true, null: false
  end

  add_index "user_skillsets", ["skillset_id"], name: "index_user_skillsets_on_skillset_id", using: :btree
  add_index "user_skillsets", ["user_id"], name: "index_user_skillsets_on_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",      limit: 255,                   null: false
    t.string   "name",       limit: 255,                   null: false
    t.boolean  "admin",                    default: false
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
    t.text     "jwt",        limit: 65535
    t.string   "ip",         limit: 255
    t.boolean  "lock",                     default: false
    t.boolean  "protected",                default: false
    t.string   "password",   limit: 255
    t.boolean  "confirmed",                default: false
    t.string   "token",      limit: 255
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree

  add_foreign_key "comments", "resources"
  add_foreign_key "comments", "sprint_states"
  add_foreign_key "comments", "users"
  add_foreign_key "contributors", "sprints"
  add_foreign_key "contributors", "users"
  add_foreign_key "logins", "users"
  add_foreign_key "resources", "sprint_states"
  add_foreign_key "resources", "sprints"
  add_foreign_key "resources", "users"
  add_foreign_key "sprint_skillsets", "skillsets"
  add_foreign_key "sprint_skillsets", "sprints"
  add_foreign_key "sprint_states", "sprints"
  add_foreign_key "sprint_states", "states"
  add_foreign_key "sprint_timelines", "comments"
  add_foreign_key "sprint_timelines", "labels"
  add_foreign_key "sprint_timelines", "sprint_states"
  add_foreign_key "sprint_timelines", "sprints"
  add_foreign_key "sprint_timelines", "states"
  add_foreign_key "sprints", "projects"
  add_foreign_key "sprints", "users"
  add_foreign_key "user_roles", "roles"
  add_foreign_key "user_roles", "users"
  add_foreign_key "user_skillsets", "skillsets"
  add_foreign_key "user_skillsets", "users"
end

class AddComments < ActiveRecord::Migration[4.2]
    def change
        create_table "comments", force: :cascade do |t|
            t.integer  "user_id",       limit: 4,                null: false
            t.integer  "sprint_state_id",       limit: 4,                null: false
            t.integer "comment_id", limit: 4, null: true
            t.integer "contributor_id", limit: 4, null: true
            t.datetime "created_at",                          null: false
            t.datetime "updated_at",                          null: false
        end

        create_table "sprint_states", force: :cascade do |t|
            t.integer  "sprint_id",       limit: 4,                null: false
            t.integer "state_id", limit: 4, null: false
            t.datetime "deadline"
            t.datetime "created_at",                          null: false
            t.datetime "updated_at",                          null: false
            t.integer "user_id", null: true #winner
        end

        create_table "contributors", force: :cascade do |t|
            t.integer  "user_id",       limit: 4,   null: false
            t.integer  "sprint_state_id",         limit: 4,   null: false
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

        add_index "contributors", ["user_id"]
        add_index "contributors", ["sprint_state_id"]

        add_foreign_key "contributors", "users", column: "user_id"
        add_foreign_key "contributors", "sprint_states", column: "sprint_state_id"

        add_column :sprint_timelines, :comment_id, :integer, :null => true
        add_column :sprint_timelines, :sprint_state_id, :integer, :null => true

        add_foreign_key "sprint_timelines", "comments", column: "comment_id"
        add_foreign_key "sprint_timelines", "sprint_states", column: "sprint_state_id"

        add_index "comments", ["sprint_state_id"]
        add_index "comments", ["user_id"]

        add_index "sprint_states", ["sprint_id"]

        add_foreign_key "comments", "users", column: "user_id"
        add_foreign_key "comments", "sprint_states", column: "sprint_state_id"
        add_foreign_key "comments", "contributors", column: "contributor_id"

        add_foreign_key "sprint_states", "sprints", column: "sprint_id"
        add_foreign_key "sprint_states", "states", column: "state_id"

    end
end

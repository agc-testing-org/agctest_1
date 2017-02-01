class AddComments < ActiveRecord::Migration
    def change
        create_table "comments", force: :cascade do |t|
            t.integer  "user_id",       limit: 4,                null: false
            t.integer  "sprint_state_id",       limit: 4,                null: false
            t.integer "comment_id", limit: 4, null: true
            t.integer "resource_id", limit: 4, null: true
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

        create_table "resources", force: :cascade do |t|
            t.integer "sprint_state_id", limit: 4, null: false
            t.integer  "user_id",       limit: 4,                null: false
            t.integer  "sprint_id",       limit: 4,                null: false
            t.text  "solution",       null: true
            t.datetime "created_at",                          null: false
            t.datetime "updated_at",                          null: false
        end

        add_column :sprint_timelines, :comment_id, :integer, :null => true
        add_column :sprint_timelines, :sprint_state_id, :integer, :null => true

        add_foreign_key "sprint_timelines", "comments", column: "comment_id"
        add_foreign_key "sprint_timelines", "sprint_states", column: "sprint_state_id"

        add_index "comments", ["sprint_state_id"]
        add_index "comments", ["user_id"]

        add_index "sprint_states", ["sprint_id"]

        add_index "resources", ["sprint_id"]
        add_index "resources", ["user_id"]
        add_index "resources", ["sprint_state_id"]

        add_foreign_key "comments", "users", column: "user_id"
        add_foreign_key "comments", "sprint_states", column: "sprint_state_id"
        add_foreign_key "comments", "resources", column: "resource_id"

        add_foreign_key "sprint_states", "sprints", column: "sprint_id"
        add_foreign_key "sprint_states", "states", column: "state_id"

        add_foreign_key "resources", "sprint_states", column: "sprint_state_id"
        add_foreign_key "resources", "sprints", column: "sprint_id"
        add_foreign_key "resources", "users", column: "user_id"

    end
end

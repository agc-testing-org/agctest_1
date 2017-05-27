class AddCommentText < ActiveRecord::Migration[4.2]
    def change
        add_column :comments, :text, :text, :null => false

        create_table "votes", force: :cascade do |t|
            t.integer  "user_id",       limit: 4,                null: false
            t.integer  "sprint_state_id",       limit: 4,                null: false
            t.integer "comment_id", limit: 4, null: true
            t.integer "contributor_id", limit: 4, null: true
            t.datetime "created_at",                          null: false
            t.datetime "updated_at",                          null: false
        end


        add_index "votes", ["sprint_state_id"]
        add_index "votes", ["user_id"]

        add_foreign_key "votes", "users", column: "user_id"
        add_foreign_key "votes", "sprint_states", column: "sprint_state_id"
        add_foreign_key "votes", "contributors", column: "contributor_id"

    end
end

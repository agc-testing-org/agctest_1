class CreateTeams < ActiveRecord::Migration[4.2]
    def change
        create_table "teams", force: :cascade do |t|
            t.string   "name",       limit: 255, null: false
            t.string   "owner",      limit: 255, null: false
            t.datetime "created_at",             null: false
            t.datetime "updated_at",             null: false
        end

        create_table "user_teams", force: :cascade do |t|
            t.integer  "user_id",       limit: 4,        null: true
            t.integer  "sender_id",                      null: false
            t.string   "user_email",                     null: true
            t.integer  "team_id",       limit: 4,        null: false
            t.boolean  "accepted",      default: false
            t.datetime "created_at",                     null: false
            t.datetime "updated_at",                     null: false
        end

        add_index "user_teams", ["user_id"], name: "index_user_team_on_user", using: :btree
        add_foreign_key "user_teams", "users", column: "user_id"
        add_foreign_key "user_teams", "users", column: "sender_id"
        add_foreign_key "user_teams", "teams", column: "team_id"

        #add_index "user_teams", ["user_id", "sender_id"], unique: true, name: 'index_sender_id_and_user_id_on_user_teams'
    end
end

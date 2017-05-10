class CreateTeams < ActiveRecord::Migration
    def change
        create_table "teams", force: :cascade do |t|
            t.string   "name",       limit: 255, null: false
            t.string   "owner",      limit: 255, null: false
            t.datetime "created_at",             null: false
            t.datetime "updated_at",             null: false
        end

        create_table "user_teams", force: :cascade do |t|
            t.integer  "user_id",       limit: 4,        null: false
            t.integer  "team_id",       limit: 4,        null: false
            t.string   "invite_token",  limit: 255,      null: true
            t.boolean  "accepted",      default: false
            t.datetime "created_at",                     null: false
            t.datetime "updated_at",                     null: false
        end

        add_index "user_teams", ["user_id"], name: "index_user_team_on_user", using: :btree
        add_foreign_key "user_teams", "users", column: "user_id"
        add_foreign_key "user_teams", "teams", column: "team_id"
    end
end
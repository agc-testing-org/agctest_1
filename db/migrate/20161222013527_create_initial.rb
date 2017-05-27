class CreateInitial < ActiveRecord::Migration[4.2]
    def change
        create_table "users", force: :cascade do |t|
            t.string   "email",      limit: 255,                   null: false
            t.string   "name",      limit: 255,                   null: false
            t.boolean  "admin",                    default: false
            t.datetime "created_at",                               null: false
            t.datetime "updated_at",                               null: false
            t.text     "jwt",        limit: 65535
            t.string   "ip",         limit: 255
            t.boolean  "lock",                     default: false
            t.boolean "protected", default: false
            t.string   "password",   limit: 255, null:true
            t.boolean  "confirmed",              default: false
            t.string   "token",      limit: 255, null:true
        end
        add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree

        create_table "logins", force: :cascade do |t|
            t.integer  "user_id",       limit: 4,   null: false
            t.string   "ip",         limit: 255, null: false
            t.datetime "created_at",             null: false
            t.datetime "updated_at",             null: false
        end
        add_index "logins", ["user_id"], name: "index_logins_on_user", using: :btree
        add_index "logins", ["ip"], name: "index_logins_on_ip", using: :btree
        add_foreign_key "logins", "users", column: "user_id"

    end
end

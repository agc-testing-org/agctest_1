class CreateRoles < ActiveRecord::Migration
    def change
        create_table "roles", force: :cascade do |t|
            t.string   "name",       limit: 255, null: false
            t.datetime "created_at",             null: false
            t.datetime "updated_at",             null: false
        end

        Role.create(name: "product")
        Role.create(name: "quality")
        Role.create(name: "development")
        Role.create(name: "design")

        create_table "user_roles", force: :cascade do |t|
            t.integer  "user_id",       limit: 4,                null: false
            t.integer  "role_id",   limit: 4,                null: false
            t.datetime "created_at",                          null: false
            t.datetime "updated_at",                          null: false
            t.boolean "active", null: false
        end

        add_index "user_roles", ["user_id"], name: "index_user_roles_on_user", using: :btree
        add_foreign_key "user_roles", "users", column: "user_id"
        add_foreign_key "user_roles", "roles", column: "role_id"
    end
end

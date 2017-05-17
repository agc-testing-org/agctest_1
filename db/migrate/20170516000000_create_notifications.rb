class CreateNotifications < ActiveRecord::Migration
    def change

        create_table "notifications", force: :cascade do |t|
            t.string   "subject",    limit: 255, null: false
            t.text   "body",         limit: 255, null: false
            t.integer "sprint_state_id",         null: true
            t.integer "contributor_id",          null: true
            t.integer  "user_id",                null: true
            t.integer "sprint_timeline_id",      null: false
            t.integer "sprint_id",               null: false
        end

        create_table "user_notifications", force: :cascade do |t|
            t.integer  "user_id",                null: false    
            t.integer  "notifications_id",       null: false
            t.boolean  "read",     default: false
        end

        add_index "user_notifications", ["notifications_id"]
        add_index "user_notifications", ["user_id"]
        add_index "user_notifications", ["user_id", "notifications_id"], unique: true, name: 'index_notification_id_and_user_id_on_user_notification'
        add_index "notifications", ["sprint_timeline_id"], unique: true, name: 'index_sprint_timeline_id_on_notification'

        add_foreign_key "user_notifications", "notifications", column: "notifications_id"
        add_foreign_key "user_notifications", "users", column: "user_id"

        create_table "user_contributors", force: :cascade do |t|
            t.integer  "user_id",                null: false    
            t.integer  "contributors_id",       null: false
        end
        
        add_index "user_contributors", ["user_id", "contributors_id"], unique: true, name: 'index_contributors_id_and_user_id_on_user_contributor'

        add_column :sprint_timelines, :contributor_id, :integer, :null => true
        add_foreign_key "sprint_timelines", "contributors", column: "contributor_id"

        create_table "user_connections", force: :cascade do |t|
            t.integer "user_id",                  null: false    
            t.integer "contact_id",               null: false
            t.integer "confirmed", default: 1
            t.boolean "read", default: false
        end

        add_index "user_connections", ["contact_id"]
        add_index "user_connections", ["user_id"]
        add_index "user_connections", ["user_id", "contact_id"], unique: true, name: 'index_contact_id_and_user_id_on_user_connections'

        create_table "connection_states", force: :cascade do |t|
            t.string   "name",       limit: 255, null: false
        end
        
       ConnectionState.create(name: "none")
       ConnectionState.create(name: "confirmed")
       ConnectionState.create(name: "rejected")
    
    end
end
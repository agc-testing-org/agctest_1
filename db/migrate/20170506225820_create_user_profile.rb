class CreateUserProfile < ActiveRecord::Migration
    def change
        create_table "user_profiles", force: :cascade do |t|
            t.integer  "user_id",       limit: 4,   null: false
            t.string   "headline",         limit: 255, null: true
            t.string   "location_country_code",  limit: 255, null: true
            t.string   "location_name", limit: 255, null: true
            t.datetime "created_at",             null: false
            t.datetime "updated_at",             null: false
        end
        create_table "user_positions", force: :cascade do |t|
            t.integer  "user_profile_id",  limit: 4,   null: false
            t.string   "title",  limit: 255, null: true
            t.string   "size",  limit: 255, null: true
            t.integer "start_year",             null: true 
            t.integer "end_year",             null: true
            t.string   "company",  limit: 255, null: true
            t.string   "industry",  limit: 255, null: true
            t.datetime "created_at",             null: false
            t.datetime "updated_at",             null: false 
        end
    end
end

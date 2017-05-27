class AddUserProfilePositionsForeignKey < ActiveRecord::Migration[4.2]
    def change
        add_foreign_key "user_profiles", "users", column: "user_id"
        add_foreign_key "user_positions", "user_profiles", column: "user_profile_id"
    end
end

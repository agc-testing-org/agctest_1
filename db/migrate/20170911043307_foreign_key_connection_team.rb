class ForeignKeyConnectionTeam < ActiveRecord::Migration[5.1]
    def change
        add_foreign_key "user_connections", "teams"
    end
end

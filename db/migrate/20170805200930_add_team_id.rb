class AddTeamId < ActiveRecord::Migration[5.1]
    def change
        add_column :user_connections, :team_id, :integer
    end
end

class Shares < ActiveRecord::Migration[5.1]
    def change
        add_column :user_teams, :profile_id, :integer, :null => true
        Seat.create(:name => "share")
    end
end

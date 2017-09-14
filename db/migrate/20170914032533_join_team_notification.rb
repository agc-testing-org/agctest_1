class JoinTeamNotification < ActiveRecord::Migration[5.1]
    def change
        add_column :sprint_timelines, :team_id, :integer, :null => true
        begin
            Notification.create({:name => "join", :description => "team invitation accepted"})
        end
    end
end

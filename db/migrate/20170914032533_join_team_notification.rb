class JoinTeamNotification < ActiveRecord::Migration[5.1]
    def change
        add_column :sprint_timelines, :team_id, :integer, :null => true

        create_table "team_notifications", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
            t.integer "team_id", null: false
            t.integer "sprint_timeline_id", null: false 
            t.datetime "created_at", null: false
            t.datetime "updated_at", null: false
        end
        add_foreign_key :team_notifications, :teams
        add_foreign_key :team_notifications, :sprint_timelines

        begin
            Notification.create({:name => "join", :description => "team invitation accepted"})
        end
    end
end

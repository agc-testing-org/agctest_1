class UpdateSprintTimelines < ActiveRecord::Migration[5.1]
    def up
        create_table "notifications", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
            t.string "name", null: false
            t.datetime "created_at", null: false
        end

        new = Notification.create(:name => "new")
        transition = Notification.create(:name => "transition")
        comment = Notification.create(:name => "comment")
        vote = Notification.create(:name => "vote")
        winner = Notification.create(:name => "winner")

        SprintTimeline.where({:diff => "new"}).update_all({:diff => new.id})
        SprintTimeline.where({:diff => "transition"}).update_all({:diff => transition.id})
        SprintTimeline.where({:diff => "comment"}).update_all({:diff => comment.id})
        SprintTimeline.where({:diff => "vote"}).update_all({:diff => vote.id})
        SprintTimeline.where({:diff => "winner"}).update_all({:diff => winner.id})
        change_column :sprint_timelines, :diff, :integer
        rename_column :sprint_timelines, :diff, :notification_id
    end

    def down
        drop_table "notifications" 
        rename_column :sprint_timelines, :notification_id, :diff
    end
end

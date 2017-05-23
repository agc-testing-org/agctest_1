class AddVotes < ActiveRecord::Migration
    def change
        add_column :sprint_timelines, :vote_id, :integer, :null => true
        add_foreign_key "sprint_timelines", "votes", column: "vote_id"
    end
end
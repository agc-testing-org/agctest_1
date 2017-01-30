class AddProjectId < ActiveRecord::Migration
    def change
        add_column :sprint_timelines, :project_id, :integer, :null => false
        add_column :sprint_timelines, :user_id, :integer, :null => false
    end
end

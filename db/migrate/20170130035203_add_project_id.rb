class AddProjectId < ActiveRecord::Migration[4.2]
    def change
        add_column :sprint_timelines, :project_id, :integer, :null => false
        add_column :sprint_timelines, :user_id, :integer, :null => false
    end
end

class AddProject < ActiveRecord::Migration[4.2]
    def change
        add_column :notifications, :project_org, :string, :null => false
        add_column :notifications, :created_at, :datetime, :null => false
        add_column :notifications, :sprint_name, :string, :null => false
        add_column :notifications, :project_name, :string, :null => false
        add_column :notifications, :project_id, :integer, :null => false
        add_column :user_connections, :user_name, :string, :null => false
    end
end

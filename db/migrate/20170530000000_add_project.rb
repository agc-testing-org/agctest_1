class AddProject < ActiveRecord::Migration
    def change
        add_column :notifications, :project, :string, :null => false
        add_column :notifications, :created_at, :datetime, :null => false
        add_column :notifications, :sprint_name, :string, :null => false
    end
end
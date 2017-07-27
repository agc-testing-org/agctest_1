class UpdateProjectForClone < ActiveRecord::Migration[5.1]
    def change
        add_column :projects, :prepared, :boolean, :null => true
        add_column :projects, :preparing, :boolean, :null => true
        add_column :projects, :commit, :string, :null => true
        add_column :projects, :commit_remote, :string, :null => true
        add_column :projects, :commit_success, :boolean, :null => true
    end
end

class AddProjectInfo < ActiveRecord::Migration[5.1]
    def change
        add_column :projects, :description, :string, :null => true
        add_column :projects, :caption, :text, :null => true
    end
end

class AddMerge < ActiveRecord::Migration
    def change
        add_column :sprint_states, :merged, :boolean, :null => true
        add_column :sprint_states, :pull_request, :integer, :null => true
    end
end

class AddAfter < ActiveRecord::Migration
    def change
        add_column :sprint_timelines, :after, :integer, :null => true
    end
end

class AddAfter < ActiveRecord::Migration[4.2]
    def change
        add_column :sprint_timelines, :after, :integer, :null => true
    end
end

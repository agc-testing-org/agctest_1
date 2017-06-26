class AddNextSprintStateToSprintTimelines < ActiveRecord::Migration[5.1]
  def change
    add_column :sprint_timelines, :next_sprint_state_id, :integer, :null => true
  end
end

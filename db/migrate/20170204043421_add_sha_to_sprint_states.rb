class AddShaToSprintStates < ActiveRecord::Migration[4.2]
  def change
    add_column :sprint_states, :sha, :string, :null => true
    add_column :contributors, :project_id, :string, :null => false 
  end
end

class AddShaToSprintStates < ActiveRecord::Migration
  def change
    add_column :sprint_states, :sha, :string, :null => true
  end
end

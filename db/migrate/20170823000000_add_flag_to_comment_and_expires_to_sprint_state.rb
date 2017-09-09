class AddFlagToCommentAndExpiresToSprintState < ActiveRecord::Migration[5.1]
  def change
    add_column :comments, :review, :boolean, :null => true
    add_column :sprint_states, :expires, :datetime, :null => true
  end
end
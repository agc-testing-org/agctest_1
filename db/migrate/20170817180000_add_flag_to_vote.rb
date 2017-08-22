class AddFlagToVote < ActiveRecord::Migration[5.1]
  def change
    add_column :votes, :flag, :boolean, :null => true
  end
end
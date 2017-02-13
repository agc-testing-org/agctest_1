class AddCommentText < ActiveRecord::Migration
  def change
    add_column :comments, :text, :text, :null => false
  end
end

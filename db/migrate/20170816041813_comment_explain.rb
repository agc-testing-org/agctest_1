class CommentExplain < ActiveRecord::Migration[5.1]
  def change
    add_column :comments, :explain, :boolean, :default => false
  end
end

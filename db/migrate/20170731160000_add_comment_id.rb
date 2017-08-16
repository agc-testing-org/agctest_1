class AddCommentId < ActiveRecord::Migration[5.1]
  def change
    add_column :votes, :comment_id, :integer, :null => true
    Notification.create(:name => "comment vote", :description => "vote received for the comment you left")
  end
end

class AddCommentBody < ActiveRecord::Migration[4.2]
    def change
        add_column :notifications, :comment_body, :string, :null => true
    end
end
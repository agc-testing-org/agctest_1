class UpdateCommentBodyType < ActiveRecord::Migration[5.1]
    def change
        change_column(:notifications, :comment_body, :text, :null => true)  
    end
end

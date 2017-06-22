class UpdateCommentBodyType < ActiveRecord::Migration[5.1]
    def up
        change_column(:notifications, :comment_body, :text, :null => true)  
    end

    def down
        #change_column(:notifications, :comment_body, :string, :null => true)
    end
end

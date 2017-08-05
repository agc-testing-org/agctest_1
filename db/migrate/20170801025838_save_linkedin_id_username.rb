class SaveLinkedinIdUsername < ActiveRecord::Migration[5.1]
    def change
        add_column :user_profiles, :l_id, :string, :null => false
        add_column :user_profiles, :username, :string, :null => false
    end
end

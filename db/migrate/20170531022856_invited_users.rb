class InvitedUsers < ActiveRecord::Migration[5.1]
  def change
    change_column :users, :name, :string, :null => true
    rename_column :users, :name, :first_name
    add_column :users, :last_name, :string, :null => true
  end
end

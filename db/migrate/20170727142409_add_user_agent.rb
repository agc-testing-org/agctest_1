class AddUserAgent < ActiveRecord::Migration[5.1]
  def change
    add_column :logins, :user_agent, :string, :null => true
    remove_column :logins, :updated_at
  end
end

class DropNameFromUserConnections < ActiveRecord::Migration[5.1]
  def change
    remove_column :user_connections, :user_name
  end
end

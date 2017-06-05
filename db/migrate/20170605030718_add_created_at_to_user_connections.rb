class AddCreatedAtToUserConnections < ActiveRecord::Migration[5.1]
  def change
    add_timestamps(:user_connections, null: true)
    add_timestamps(:user_notifications, null: true)
  end
end

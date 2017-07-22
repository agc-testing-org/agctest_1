class ForeignKeyConnections < ActiveRecord::Migration[5.1]
  def change
    add_foreign_key :user_connections, :users
    add_foreign_key :user_connections, :users, :column => "contact_id"
  end
end

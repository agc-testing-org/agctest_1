class DropNotifications < ActiveRecord::Migration[5.1]
  def up
    drop_table :notifications
  end
end

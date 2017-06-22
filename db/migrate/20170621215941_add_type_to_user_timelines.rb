class AddTypeToUserTimelines < ActiveRecord::Migration[5.1]
  def change
    add_column :sprint_timelines, :diff, :string, :null => false
    add_column :sprint_timelines, :processed, :integer, :null => true, :default => 0
    add_column :user_notifications, :sprint_timeline_id, :integer, :null => false
    remove_foreign_key :user_notifications, column: :notifications_id
    remove_foreign_key :user_notifications, column: :user_id
    remove_index :user_notifications, column: ["user_id", "notifications_id"]
    remove_column :user_notifications, :notifications_id

  end
end

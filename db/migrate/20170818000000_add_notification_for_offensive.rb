class AddNotificationForOffensive < ActiveRecord::Migration[5.1]
  def change
      Notification.create("name": "comment offensive", "description": "comment is offensive")
      Notification.create("name": "sprint comment offensive", "description": "sprint comment is offensive")
  end
end
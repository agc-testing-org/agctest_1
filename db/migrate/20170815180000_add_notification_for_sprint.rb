class AddNotificationForSprint < ActiveRecord::Migration[5.1]
  def change
      Notification.create("name": "sprint comment", "description": "comment received for the sprint idea")
      Notification.create("name": "sprint vote", "description": "vote received for the sprint idea")
      Notification.create("name": "sprint comment vote", "description": "vote received for the comment you left for sprint idea")
  end
end
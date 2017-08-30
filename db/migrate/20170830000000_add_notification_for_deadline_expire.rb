class AddNotificationForDeadlineExpire < ActiveRecord::Migration[5.1]
  def change
      Notification.create("name": "deadline expire", "description": "the deadline for the sprint expire")
  end
end

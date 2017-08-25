class AddNotificationForDeadline < ActiveRecord::Migration[5.1]
  def change
      Notification.create("name": "deadline", "description": "the deadline for the sprint set, you can offer a solution")
  end
end

class AddNotificationForDeadline < ActiveRecord::Migration[5.1]
  def change
      Notification.create("name": "deadline", "description": "deadline set for sprint state that corresponds to your role subscriptions (last call)")
  end
end

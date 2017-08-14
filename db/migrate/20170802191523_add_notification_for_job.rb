class AddNotificationForJob < ActiveRecord::Migration[5.1]
  def change
      Notification.create("name": "job", "description": "new job listing that corresponds with your role subscriptions")
  end
end

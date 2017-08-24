class AddNotificationForOffensive < ActiveRecord::Migration[5.1]
  def change
      Notification.create("name": "comment offensive", "description": "comment you posted on a solution has been flagged")
      Notification.create("name": "sprint comment offensive", "description": "comment you posted for a sprint idea has been flagged")
  end
end

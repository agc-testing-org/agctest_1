class NotificationWorker
	include Sidekiq::Worker
	def perform
		notification = Issue.new
		notifications = notification.recently_changed_sprint?
        user_notification = notification.create_user_notification
    end
end
class UserNotificationGetWorker
	include Sidekiq::Worker
	
	def perform id 
		activity = Activity.new
		unread = activity.user_notifications_that_need_to_be_mailed id
		unread.each do |n|
			UserNotificationMailWorker.perform_async id, n.user_id.to_s
		end
		return (unread)
	end
end

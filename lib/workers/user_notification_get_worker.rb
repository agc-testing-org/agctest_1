class UserNotificationGetWorker
	include Sidekiq::Worker
    activity = Activity.new
    return activity.user_notifications_that_need_to_be_mailed
end

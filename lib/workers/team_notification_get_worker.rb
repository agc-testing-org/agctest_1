class TeamNotificationGetWorker
	include Sidekiq::Worker
	
    def perform id 
        activity = Activity.new
        unread = activity.team_notifications_that_need_to_be_mailed id
        if unread
            unread.each do |n|
                UserNotificationMailWorker.perform_async id, n[:user_id]
            end
            return true 
        else
            return true
        end
    end
end

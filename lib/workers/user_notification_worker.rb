class UserNotificationWorker
    include Sidekiq::Worker
    def perform id
        notification = Issue.new

        users = (notification.user_notifications_for_contributor id) || (notification.user_notifications_for_owner id) || (notification.user_notifications_for_contributors_with_winner id) || (notification.user_notifications_by_comments id) || (notification.user_notifications_by_votes id) || (notification.user_notifications_by_roles id) #|| (notification.user_notifications_by_skillsets id)

        user_notification = notification.record_user_notifications users
        
        if user_notification
            notification.process_user_notification id
        end
    end
end

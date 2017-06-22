class UserNotificationWorker
    include Sidekiq::Worker
    def perform id
        notification = Issue.new
        user_notification = notification.create_user_notification id
        if user_notification
            notification.process_user_notification id
        end
    end
end

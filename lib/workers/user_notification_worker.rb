class UserNotificationWorker
    include Sidekiq::Worker
    
    def perform id
        activity = Activity.new
        process = activity.process_notification id
        UserNotificationGetWorker.perform_async id 
        return (process)
    end
end



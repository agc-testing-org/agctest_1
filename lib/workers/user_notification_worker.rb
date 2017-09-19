class UserNotificationWorker
    include Sidekiq::Worker
    
    def perform id
        activity = Activity.new
        process = activity.process_notification id
        team_process = activity.process_team_notification id
        UserNotificationGetWorker.perform_async id
        TeamNotificationGetWorker.perform_async id
        return (process && team_process)
    end
end



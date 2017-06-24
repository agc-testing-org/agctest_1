class UserNotificationWorker
    include Sidekiq::Worker
    def perform id

        activity = Activity.new
        return (activity.process_notification id)

    end
end

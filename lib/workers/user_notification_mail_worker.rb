class UserNotificationMailWorker
    include Sidekiq::Worker
    def perform id 
        account = Account.new
        return account.create_notification_email id
    end
end

class UserNotificationMailWorker
    include Sidekiq::Worker
    
    def perform id, user_id
        account = Account.new
        return account.create_notification_email id, user_id
    end
end

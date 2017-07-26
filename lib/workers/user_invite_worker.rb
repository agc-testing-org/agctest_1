class UserInviteWorker
    include Sidekiq::Worker
    def perform token
        account = Account.new
        return account.mail_invite token
    end
end

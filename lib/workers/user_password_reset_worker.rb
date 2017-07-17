class UserPasswordResetWorker
    include Sidekiq::Worker
    def perform name, email, token
        account = Account.new
        return account.mail_token name, email, token
    end
end

class UserRegisterWorker
    include Sidekiq::Worker
    def perform email, first_name
        account = Account.new
        return account.create_email email, first_name
    end
end

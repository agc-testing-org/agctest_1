class UserInviteWorker
    include Sidekiq::Worker
    def perform token
        account = Account.new
        invite = account.get_invitation token
        return account.mail_invite invite.take
    end
end

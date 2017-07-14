class ContributorSyncWorker
    include Sidekiq::Worker
    def perform contributor_id, username
        repo = Repo.new
        return (repo.sync contributor_id, username)
    end
end

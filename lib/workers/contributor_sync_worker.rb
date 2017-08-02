class ContributorSyncWorker
    include Sidekiq::Worker
    def perform session, github_token, contributor_id, username
        repo = Repo.new
        return (repo.sync session, github_token, contributor_id, username)
    end
end

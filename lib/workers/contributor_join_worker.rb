class ContributorJoinWorker
    include Sidekiq::Worker
    def perform session, github_token, contributor_id, username
        repo = Repo.new
        return (repo.join session, github_token, contributor_id, username)
    end
end

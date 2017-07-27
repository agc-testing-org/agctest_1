class UserCreateProjectWorker
    include Sidekiq::Worker
    def perform id
        repo = Repo.new
        return (repo.copy id)
    end
end

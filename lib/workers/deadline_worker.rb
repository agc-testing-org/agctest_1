class DeadlineWorker
    include Sidekiq::Worker
    def perform sprint_state_id
        issue = Issue.new
        sprint_state = issue.get_sprint_state sprint_state_id

        contributors = sprint_state.contributors.where("contributors.commit_remote IS NOT NULL").each do |c|
            ContributorSyncWorker.perform_async c.id, c.user.github_username
        end

        DeadlineNotificationWorker.perform_at (Time.now.utc + 1.hour), sprint_state.sprint[:user_id], sprint_state.sprint.project_id, sprint_state.sprint_id, sprint_state_id, sprint_state.state.id
    end
end

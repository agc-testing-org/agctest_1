class DeadlineWorker
    include Sidekiq::Worker
    def perform sprint_user_id, sprint_state_id
        issue = Issue.new
        log_params = {:user_id => sprint_user_id, :sprint_state_id => sprint_state_id, :notification_id => Notification.find_by({:name => "peer review"}).id}
        return (issue.log_event log_params)
    end
end

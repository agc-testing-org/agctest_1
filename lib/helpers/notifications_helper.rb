module NotificationsHelper

    def notifications_result notifications, for_team
        account = Account.new
        response = []
        notifications.each_with_index do |notification,i|
            response[i] = notification.as_json

            if for_team && notification.contributor && (notification[:team_user] == notification.contributor.user[:id])
                response[i][:contributor_first_name] = notification.contributor.user.first_name
                response[i][:contributor_profile] = account.get_profile notification.contributor.user
            end

            response[i][:user_profile] = account.get_profile notification.user
            if for_team && notification.user && (notification[:team_user] == notification.user[:id])
                response[i][:user_first_name] = notification.user.first_name
            end

            response[i][:sprint] = notification.sprint
            response[i][:project] = notification.project
            response[i][:sprint_state] = notification.sprint_state
            response[i][:next_sprint_state] = notification.next_sprint_state
            response[i][:comment] = notification.comment
            response[i][:vote] = notification.vote
            response[i][:notification] = notification.notification

            if notification.vote && notification.vote.comment
                response[i][:comment_vote] = notification.vote.comment
                response[i][:comment_vote_user_profile] = account.get_profile notification.vote.comment.user
                if for_team && (notification[:team_user] == notification.vote.comment.user[:id])
                    response[i][:comment_vote_first_name] = notification.user.first_name
                end
            end

            if notification.job
                response[i][:job_title] = notification.job.title
                response[i][:job_team_name] = notification.job.team.name
                response[i][:job_company] = notification.job.team.company
            end
        end
        return response
    end
end

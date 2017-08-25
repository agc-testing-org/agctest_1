class Activity
    include Obfuscate
    def initialize

    end

    def user_notifications_by_skillsets sprint_timeline_id #TODO - this should apply to developers only, and probably as an extension of user_notifications_by_roles
        # all users that subscribe to a skillset listed for the sprint
        begin
            return SprintTimeline.where(:id => sprint_timeline_id).joins("LEFT JOIN projects ON (sprint_timelines.project_id = projects.id AND projects.hidden != 1) INNER JOIN sprint_skillsets ON sprint_skillsets.sprint_id=sprint_timelines.sprint_id INNER JOIN user_skillsets ON user_skillsets.skillset_id = sprint_skillsets.skillset_id").where("user_skillsets.active = 1 and sprint_skillsets.active=1").select("user_skillsets.user_id")
        rescue => e
            puts e
            return [] 
        end
    end

    def user_notifications_by_roles sprint_timeline_id
        # all users that subscribe to a role that corresponds to a sprint state/phase change (transition notification_id)
        begin
            return SprintTimeline.where(:id => sprint_timeline_id, :notification_id => Notification.find_by({:name => "transition"}).id).joins("INNER JOIN states ON sprint_timelines.state_id = states.id INNER JOIN role_states ON states.id = role_states.state_id INNER JOIN user_roles ON user_roles.role_id = role_states.role_id AND user_roles.active = 1").where("user_roles.user_id != sprint_timelines.user_id").select("user_roles.user_id")
        rescue => e
            puts e
            return []
        end
    end 

    def user_notifications_for_job sprint_timeline_id
        # all users that subscribe to a role that corresponds to a job role
        begin
            return SprintTimeline.where(:id => sprint_timeline_id, :notification_id => Notification.find_by({:name => "job"}).id).joins("INNER JOIN jobs ON jobs.id = sprint_timelines.job_id INNER JOIN user_roles ON user_roles.role_id = jobs.role_id AND user_roles.active = 1").where("user_roles.user_id != sprint_timelines.user_id").select("user_roles.user_id")
        rescue => e
            puts e
            return []
        end
    end

    def user_notifications_for_job_owner sprint_timeline_id
        # job owner
        begin
            return SprintTimeline.where(:id => sprint_timeline_id).joins("INNER JOIN jobs ON jobs.id = sprint_timelines.job_id").where("jobs.user_id != sprint_timelines.user_id").select("jobs.user_id")
        rescue => e
            puts e
            return []
        end
    end   

    def user_notifications_for_job_contributors sprint_timeline_id
        #people that propose ideas (sprints) for a job
        begin
            return SprintTimeline.where(:id => sprint_timeline_id, :notification_id => Notification.find_by({:name => "new"}).id).joins("INNER JOIN sprints ON sprints.job_id = sprint_timelines.job_id").where("sprints.user_id != sprint_timelines.user_id").select("sprints.user_id")
        rescue => e
            puts e
            return []
        end
    end

    def user_notifications_for_contributor sprint_timeline_id
        # vote or comment for user that owns contribution
        begin
            return SprintTimeline.where(:id => sprint_timeline_id).joins("INNER join contributors ON sprint_timelines.contributor_id = contributors.id AND sprint_timelines.notification_id IN(#{Notification.where({:name => "vote"}).or(Notification.where({:name => "comment"})).or(Notification.where({:name => "comment vote"})).select(:id).map(&:id).join(",")})").where("contributors.user_id != sprint_timelines.user_id").select("contributors.user_id as user_id")
        rescue => e
            puts e
            return []
        end
    end

    def user_notifications_by_comments sprint_timeline_id
        # all users that commented on a specific contribution
        begin
            return SprintTimeline.where(:id => sprint_timeline_id).joins("INNER join comments ON comments.contributor_id = sprint_timelines.contributor_id").where("comments.user_id != sprint_timelines.user_id").select("comments.user_id")
        rescue => e
            puts e
            return []
        end
    end

    def user_notifications_by_votes sprint_timeline_id
        # all users that voted on a specific contribution
        begin
            return SprintTimeline.where(:id => sprint_timeline_id).joins("INNER join votes ON votes.contributor_id = sprint_timelines.contributor_id").where("votes.user_id != sprint_timelines.user_id").select("votes.user_id")
        rescue => e
            puts e
            return []
        end
    end 

    def user_notifications_by_comment_votes sprint_timeline_id
        # all users that voted on a specific comment
        begin
            return SprintTimeline.where(:id => sprint_timeline_id).joins("INNER join votes ON votes.contributor_id = sprint_timelines.contributor_id").where("votes.user_id != sprint_timelines.user_id and votes.comment_id != 0").select("votes.user_id")
        rescue => e
            puts e
            return []
        end
    end 

    def user_notifications_for_contributors_with_winner sprint_timeline_id
        # all users that contributed to a sprint state that now has a winner
        begin
            return SprintTimeline.where(:id => sprint_timeline_id, :notification_id => Notification.find_by({:name => "winner"}).id).joins("INNER join contributors ON contributors.sprint_state_id = sprint_timelines.sprint_state_id").where("contributors.user_id != sprint_timelines.user_id").select("contributors.user_id")
        rescue => e
            puts e
            return []
        end
    end

    def user_notifications_for_owner sprint_timeline_id
        # all comment and vote notifications not written by owner
        # TODO rethink ownership (anyone can create a sprint...) - also need a way to let the project owner know what's going on
        begin
            return SprintTimeline.where(:id => sprint_timeline_id).joins("INNER join sprints ON sprint_timelines.sprint_id=sprints.id").where("sprint_timelines.user_id != sprints.user_id and sprint_timelines.notification_id IN(#{Notification.where({:name => "vote"}).or(Notification.where({:name => "comment"})).or(Notification.where({:name => "comment vote"})).or(Notification.where({:name => "sprint comment"})).or(Notification.where({:name => "sprint comment vote"})).or(Notification.where({:name => "sprint vote"})).select(:id).map(&:id).join(",")})").select("sprints.user_id")
        rescue => e
            puts e
            return []
        end
    end

    def user_notifications_by_roles_for_deadline sprint_timeline_id
        # all users that subscribe to a role that corresponds to a sprint state/phase change (transition notification_id)
        begin
            return SprintTimeline.where(:id => sprint_timeline_id, :notification_id => Notification.find_by({:name => "deadline"}).id).joins("INNER JOIN states ON sprint_timelines.state_id = states.id INNER JOIN role_states ON states.id = role_states.state_id INNER JOIN user_roles ON user_roles.role_id = role_states.role_id AND user_roles.active = 1").where("user_roles.user_id != sprint_timelines.user_id").select("user_roles.user_id")
        rescue => e
            puts e
            return []
        end
    end 

    def record_user_notifications users
        begin
            UserNotification.import users, :validate => true #ignores uniqueness though
            return true
        rescue => e
            puts e
            return nil
        end
    rescue => e
        puts e
        return nil
    end

    def record_user_notifications_count sprint_timeline_id
        begin
            return UserNotification.where(:sprint_timeline_id => sprint_timeline_id).count
        rescue => e
            puts e
            return nil
        end
    end

    def store_user_notifications_count sprint_timeline_id, count, processing_or_processed
        begin
            return SprintTimeline.find_by(:id => sprint_timeline_id).update(processing_or_processed => count)
        rescue => e
            puts e
            return nil
        end
    end

    def get_decrypted_user_ids users, user_ids
        users.each do |u|
            user_ids |= [u[:user_id]]
        end
        return user_ids
    end

    def rebuild_users user_ids, sprint_timeline_id
        users = []
        user_ids.each_with_index do |u,i|
            users[i] = {:sprint_timeline_id => sprint_timeline_id, :user_id => u}
        end
        return users
    end

    def process_notification id

        user_ids = []
        user_ids = (get_decrypted_user_ids (user_notifications_for_job id), user_ids)
        user_ids = (get_decrypted_user_ids (user_notifications_for_job_contributors id), user_ids)
        user_ids = (get_decrypted_user_ids (user_notifications_for_job_owner id), user_ids)
        user_ids = (get_decrypted_user_ids (user_notifications_for_contributor id), user_ids)
        user_ids = (get_decrypted_user_ids (user_notifications_for_owner id), user_ids)
        user_ids = (get_decrypted_user_ids (user_notifications_for_contributors_with_winner id), user_ids)
        user_ids = (get_decrypted_user_ids (user_notifications_by_comments id), user_ids)
        user_ids = (get_decrypted_user_ids (user_notifications_by_votes id), user_ids)
        user_ids = (get_decrypted_user_ids (user_notifications_by_roles id), user_ids)
        user_ids = (get_decrypted_user_ids (user_notifications_by_comment_votes id), user_ids)
        user_ids = (get_decrypted_user_ids (user_notifications_by_roles_for_deadline id), user_ids)


        store_user_notifications_count id, user_ids.length, "processing"

        users = rebuild_users user_ids, id

        saved = 0
        if users
            recorded = record_user_notifications users
            if recorded
                saved = record_user_notifications_count id
            end
        end

        store_user_notifications_count id, saved, "processed"

        return (users.length == saved)
    end

    def user_notifications_that_need_to_be_mailed id
        begin
            return UserNotification.joins("INNER JOIN sprint_timelines on sprint_timelines.id=user_notifications.sprint_timeline_id LEFT JOIN user_notification_settings on user_notification_settings.user_id = user_notifications.user_id INNER JOIN users ON (users.id = user_notifications.user_id AND users.confirmed = 1) INNER JOIN notifications on sprint_timelines.notification_id = notifications.id").where("(user_notification_settings.active = 1 OR user_notification_settings.active IS NULL) and (user_notification_settings.notification_id = sprint_timelines.notification_id OR user_notification_settings.notification_id IS NULL) and user_notifications.read = 0 and notifications.name != 'vote' and sprint_timelines.id = ?", id).select("user_notifications.user_id, user_notifications.sprint_timeline_id")
        rescue => e
            puts e
            return nil
        end
    end
end

class Activity

    def initialize

    end

    #TODO - who should get the new diff type?
    def user_notifications_by_skillsets sprint_timeline_id #TODO - this should apply to developers only, and probably as an extension of user_notifications_by_roles
        # all users that subscribe to a skillset listed for the sprint
        begin
            return SprintTimeline.where(:id => sprint_timeline_id).joins("INNER JOIN sprint_skillsets ON sprint_skillsets.sprint_id=sprint_timelines.sprint_id INNER JOIN user_skillsets ON user_skillsets.skillset_id = sprint_skillsets.skillset_id").where("user_skillsets.active = 1 and sprint_skillsets.active=1").select("user_skillsets.user_id","sprint_timelines.id as sprint_timeline_id")
        rescue => e
            puts e
            return [] 
        end
    end

    def user_notifications_by_roles sprint_timeline_id
        # all users that subscribe to a role that corresponds to a sprint state/phase change (transition diff)
        begin
            return SprintTimeline.where(:id => sprint_timeline_id, :diff => "transition").joins("INNER JOIN states ON sprint_timelines.state_id = states.id INNER JOIN role_states ON states.id = role_states.state_id INNER JOIN user_roles ON user_roles.role_id = role_states.role_id AND user_roles.active = 1").where("user_roles.user_id != sprint_timelines.user_id").select("user_roles.user_id","sprint_timelines.id as sprint_timeline_id")
        rescue => e
            puts e
            return []
        end
    end 

    def user_notifications_for_contributor sprint_timeline_id
        # vote or comment for user that owns contribution
        begin
            return SprintTimeline.where(:id => sprint_timeline_id).joins("INNER join contributors ON sprint_timelines.contributor_id = contributors.id AND sprint_timelines.diff IN('vote','comment')").where("contributors.user_id != sprint_timelines.user_id").select("contributors.user_id as user_id", "sprint_timelines.id as sprint_timeline_id")
        rescue => e
            puts e
            return []
        end
    end

    def user_notifications_by_comments sprint_timeline_id
        # all users that commented on a specific contribution
        begin
            return SprintTimeline.where(:id => sprint_timeline_id).joins("INNER join comments ON comments.contributor_id = sprint_timelines.contributor_id").where("comments.user_id != sprint_timelines.user_id").select("comments.user_id", "sprint_timelines.id as sprint_timeline_id")
        rescue => e
            puts e
            return []
        end
    end

    def user_notifications_by_votes sprint_timeline_id
        # all users that voted on a specific contribution
        begin
            return SprintTimeline.where(:id => sprint_timeline_id).joins("INNER join votes ON votes.contributor_id = sprint_timelines.contributor_id").where("votes.user_id != sprint_timelines.user_id").select("votes.user_id", "sprint_timelines.id as sprint_timeline_id")
        rescue => e
            puts e
            return []
        end
    end 

    def user_notifications_for_contributors_with_winner sprint_timeline_id
        # all users that contributed to a sprint state that now has a winner
        begin
            return SprintTimeline.where(:id => sprint_timeline_id, :diff => "winner").joins("INNER join contributors ON contributors.sprint_state_id = sprint_timelines.sprint_state_id").where("contributors.user_id != sprint_timelines.user_id").select("contributors.user_id", "sprint_timelines.id as sprint_timeline_id")
        rescue => e
            puts e
            return []
        end
    end

    def user_notifications_for_owner sprint_timeline_id
        # all comment and vote notifications not written by owner
        # TODO rethink ownership (anyone can create a sprint...) - also need a way to let the project owner know what's going on
        begin
            return SprintTimeline.where(:id => sprint_timeline_id).joins("INNER join sprints ON sprint_timelines.sprint_id=sprints.id").where("sprint_timelines.user_id != sprints.user_id and sprint_timelines.diff IN('comment','vote')").select("sprints.user_id", "sprint_timelines.id as sprint_timeline_id")
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

    def user_notifications_distinct users
        return users.as_json.uniq{ |u| u.values_at(:user_id) }
    end

    def process_notification id

        users = (user_notifications_for_contributor id) + (user_notifications_for_owner id) + (user_notifications_for_contributors_with_winner id) + (user_notifications_by_comments id) + (user_notifications_by_votes id) + (user_notifications_by_roles id) 
        #+ (notification.user_notifications_by_skillsets id) #TODO - this should be an additional filter for by roles

        users = user_notifications_distinct users 

        store_user_notifications_count id, users.length, "processing"

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
end

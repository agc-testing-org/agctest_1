class Issue 
    def initialize

    end 

    def create user_id, title, description, project_id
        begin
            sprint = Sprint.create({
                user_id: user_id,
                title: title,
                description: description,
                project_id: project_id
            })
            return sprint
        rescue => e
            puts e
            return nil
        end
    end

    def get_sprint_state sprint_state_id
        begin
            return SprintState.find_by(:id => sprint_state_id)
        rescue => e
            puts e
            return nil
        end
    end


    def create_sprint_state sprint_id, state_id, sha
        begin
            sprint_state = SprintState.create({
                sprint_id: sprint_id,
                state_id: state_id,
                sha: sha
            })
            return sprint_state 
        rescue => e
            puts e
            return nil
        end
    end

    def create_comment user_id, contributor_id, sprint_state_id, text
        begin
            comment = Comment.create({
                user_id: user_id,
                sprint_state_id: sprint_state_id,
                contributor_id: contributor_id,
                text: text
            })

            return comment
        rescue => e
            puts e
            return nil
        end
    end

    def vote user_id, contributor_id, sprint_state_id
        begin
            vote = Vote.find_or_initialize_by({ # get or create vote by sprint state for specific user
                user_id: user_id,
                sprint_state_id: sprint_state_id
            })
        
            new_record = false
            previous_record = vote.contributor_id
            
            if previous_record != contributor_id.to_i # if vote is new or different (let the frontend know votes will change with new_record)
                vote.update_attributes!(:contributor_id => contributor_id)
                new_record = true
            end

            record = vote.as_json
            record[:previous] = previous_record
            record[:created] = new_record #created = false would mean no change to the frontend

            return record
        rescue => e
            puts e
            return nil
        end
    end

    def last_event sprint_id
        begin
            events = SprintTimeline.where(sprint_id: sprint_id)
            if events && events.last
                return events.last.id
            else
                return nil
            end
        rescue => e
            puts e
            return nil
        end
    end

    def log_event params 
        after = (last_event params[:sprint_id])
        begin
            params[:after] = after
            sprint_event = SprintTimeline.create(params)
            if ENV['RACK_ENV'] != "test"
                UserNotificationWorker.perform_async sprint_event.id
            end
            return sprint_event.id
        rescue => e
            puts e
            return nil
        end
    end

    def create_project org, name
        begin
            project = Project.create({
                org: org,
                name: name
            })
            return project
        rescue => e
            puts e
            return nil
        end
    end

    def get_winner sprint_state_id
        begin
            winner = SprintState.find_by(id: sprint_state_id)
        rescue => e
            puts e
            return nil
        end
    end

    def set_winner sprint_state_id, params 
        begin
            winner = SprintState.find_by(id: sprint_state_id)
            winner.update_attributes!(params)
            return winner
        rescue => e
            puts e
            return nil
        end
    end

    def get_projects query
        begin
            return Project.where(query).as_json
        rescue => e
            puts e
            return nil
        end
    end

    def get_sprint_states query, user_id
        begin
            response = Array.new
            sprint_state_results = SprintState.joins(:sprint).where(query)
            sprint_state_results.each_with_index do |ss,i|
                response[i] = ss.as_json
                response[i][:active_contribution_id] = nil
                response[i][:contributors] = []
                ss.contributors.each_with_index do |c,k|
                    if c.commit || ((sprint_state_results.length - 1) == i) # don't show empty results unless this is the current sprint_state
                        comments = c.comments.as_json
                        c.comments.each_with_index do |com,x|
                            if com.user.user_profile
                                comments[x][:user_profile] = {
                                    :id => com.user.user_profile.id,
                                    :location => com.user.user_profile.location_name,
                                    :title => com.user.user_profile.user_position.title,
                                    :industry => com.user.user_profile.user_position.industry,
                                    :size => com.user.user_profile.user_position.size,
                                    :created_at => com.user.user_profile.created_at
                                }
                            end
                        end
                        response[i][:contributors][k] = {
                            :id => c.id,
                            :created_at => c.created_at,
                            :updated_at => c.updated_at,
                            :comments => comments,
                            :votes => c.votes.as_json
                        }
                        if c.user_id == user_id
                            response[i][:contributors][k][:commit] = c.commit
                            response[i][:contributors][k][:commit_success] =  c.commit_success
                            response[i][:contributors][k][:repo] = c.repo
                            response[i][:active_contribution_id] = c.id
                        end
                    end
                end
            end
            return response
        rescue => e
            puts e
            return nil
        end
    end

    def get_sprint id # This also returns the project
        begin
            return Sprint.joins(:project).find_by(id: id)
        rescue => e
            return nil
        end
    end

    def get_sprints query
        begin
            return Sprint.joins("INNER JOIN sprint_states ON sprint_states.sprint_id = sprints.id INNER JOIN (SELECT MAX(id) last_id FROM sprint_states GROUP BY sprint_id) last_sprint_state ON sprint_states.id = last_sprint_state.last_id").where(query).as_json#.each_with_index do |s,i|
            #                response[i] = s.as_json
            #                response[i][:sprint_states] = []
            #                s.sprint_states.each_with_index do |ss,j|
            #                    response[i][:sprint_states][j] = ss.as_json
            #                end
            #            end
            #           return response
        rescue => e
            puts e
            return nil
        end 
    end 

    def get_events query
        begin
            response = Array.new
            SprintTimeline.where(query).each_with_index do |st,i|
                response[i] = st.as_json
                response[i][:sprint] = st.sprint.as_json
                response[i][:label] = st.label.as_json
            end
            return response
        rescue => e
            puts e
            return nil
        end
    end

    def get_states query
        begin
            return State.where(query).as_json
        rescue => e
            puts e
            return nil
        end
    end

    def get_skillsets
        begin
            return Skillset.all.as_json
        rescue => e
            puts e
            return nil
        end
    end

    def get_sprint_skillsets sprint_id, query
        begin            
            return Skillset.joins("LEFT JOIN sprint_skillsets ON sprint_skillsets.skillset_id = skillsets.id AND sprint_skillsets.sprint_id = #{sprint_id.to_i} OR sprint_skillsets.sprint_id is null").where(query).select("skillsets.id","skillsets.name","sprint_skillsets.active").as_json
        rescue => e
            puts e
            return nil
        end
    end

    def update_skillsets sprint_id, skillset_id, active
        begin
            ss = SprintSkillset.find_or_initialize_by(:sprint_id => sprint_id, :skillset_id => skillset_id)
            ss.update_attributes!(:active => active)
            return {:id => ss.skillset_id}
        rescue => e
            puts e
            return nil
        end
    end

    def get_user_skillsets user_id, query
        begin            
            return Skillset.joins("LEFT JOIN user_skillsets ON user_skillsets.skillset_id = skillsets.id AND user_skillsets.user_id = #{user_id.to_i} OR user_skillsets.user_id is null").where(query).select("skillsets.id","skillsets.name","user_skillsets.active").as_json
        rescue => e
            puts e
            return nil
        end
    end

    def update_user_skillsets user_id, skillset_id, active
        begin
            ss = UserSkillset.find_or_initialize_by(:user_id => user_id, :skillset_id => skillset_id)
            ss.update_attributes!(:active => active)
            return {:id => ss.skillset_id}
        rescue => e
            puts e
            return nil
        end
    end

    def object_at_index array
        if array
            return array
        else
            return Array.new 
        end 
    end

    def get_comments query #user_id == posted comment, #contributor_id = received comment
        response = {} 
        begin 
            Comment.where(query).joins("INNER JOIN contributors ON contributors.id = comments.contributor_id INNER JOIN users ON users.id = contributors.user_id").each_with_index do |comment,i| 
                response[comment.sprint_state.state_id] = (object_at_index response[comment.sprint_state.state_id])
                index = response[comment.sprint_state.state_id].length
                response[comment.sprint_state.state_id][index] = comment.as_json
                response[comment.sprint_state.state_id][index][:sprint_state] = comment.sprint_state.as_json
                response[comment.sprint_state.state_id][index][:sprint_state][:state] = comment.sprint_state.state.as_json
                response[comment.sprint_state.state_id][index][:sprint_state][:sprint] = comment.sprint_state.sprint.as_json
                response[comment.sprint_state.state_id][index][:sprint_state][:sprint][:project] = comment.sprint_state.sprint.project.as_json
            end
            return response
        rescue => e
            puts e
            return nil
        end
    end

    def get_votes query #user_id == posted comment, #contributor_id = received comment
        response = {} 
        begin 
            Vote.where(query).joins("INNER JOIN contributors ON contributors.id = votes.contributor_id INNER JOIN users ON users.id = contributors.user_id").each_with_index do |vote,i|
                response[vote.sprint_state.state_id] = (object_at_index response[vote.sprint_state.state_id])
                index = response[vote.sprint_state.state_id].length
                response[vote.sprint_state.state_id][index] = vote.as_json
                response[vote.sprint_state.state_id][index][:sprint_state] = vote.sprint_state.as_json
                response[vote.sprint_state.state_id][index][:sprint_state][:state] = vote.sprint_state.state.as_json
                response[vote.sprint_state.state_id][index][:sprint_state][:sprint] = vote.sprint_state.sprint.as_json
                response[vote.sprint_state.state_id][index][:sprint_state][:sprint][:project] = vote.sprint_state.sprint.project.as_json
            end
            return response
        rescue => e
            puts e
            return nil
        end
    end

    def get_contributors query, winner #query w/ sprint_state.contributor_id = user_id for is_winner?, #query w/ sprint_state.merged = 1 for merged?
        response = {}
        begin
            if winner
                winner_sql = "AND contributors.id = sprint_states.contributor_id"
            else
                winner_sql = ""
            end
            Contributor.where(query).joins("INNER JOIN sprint_states ON sprint_states.id = contributors.sprint_state_id INNER JOIN users ON users.id = contributors.user_id #{winner_sql}").each_with_index do |contributor,i|
                response[contributor.sprint_state.state_id] = (object_at_index response[contributor.sprint_state.state_id])
                index = response[contributor.sprint_state.state_id].length
                response[contributor.sprint_state.state_id][index] = contributor.as_json
                response[contributor.sprint_state.state_id][index][:sprint_state] = contributor.sprint_state.as_json
                response[contributor.sprint_state.state_id][index][:sprint_state][:state] = contributor.sprint_state.state.as_json
                response[contributor.sprint_state.state_id][index][:sprint_state][:sprint] = contributor.sprint_state.sprint.as_json
                response[contributor.sprint_state.state_id][index][:sprint_state][:sprint][:project] = contributor.sprint_state.sprint.project.as_json
            end
            return response
        rescue => e
            puts e
            return nil
        end
    end

    def process_user_notification sprint_timeline_id
        begin
            return SprintTimeline.find_by(:id => sprint_timeline_id).update(:processed => 1) 
        rescue => e
            puts e
            return nil
        end
    end

    def nil_for_empty res
        if !res.empty?
            return res
        else
            return nil
        end 
    end

    #TODO - who should get the new diff type?

    def user_notifications_by_skillsets sprint_timeline_id
        # all users that subscribe to a skillset listed for the sprint
        begin
            users = SprintTimeline.where(:id => sprint_timeline_id).joins("INNER JOIN sprint_skillsets ON sprint_skillsets.sprint_id=sprint_timelines.sprint_id INNER JOIN user_skillsets ON user_skillsets.skillset_id = sprint_skillsets.skillset_id").where("user_skillsets.active = 1 and sprint_skillsets.active=1").select("user_skillsets.user_id","sprint_timelines.id")
            return nil_for_empty users
        rescue => e
            puts e
            return nil
        end
    end

    def user_notifications_by_roles sprint_timeline_id
        # all users that subscribe to a role that corresponds to a sprint state/phase change (transition diff)
        begin
            users = SprintTimeline.where(:id => sprint_timeline_id, :diff => "transition").joins("INNER JOIN states ON sprint_timelines.state_id = states.id INNER JOIN role_states ON states.id = role_states.state_id INNER JOIN user_roles ON user_roles.role_id = role_states.role_id AND user_roles.active = 1").select("user_roles.user_id","sprint_timelines.id")
            return nil_for_empty users
        rescue => e
            puts e
            return nil
        end
    end 

    def user_notifications_for_contributor sprint_timeline_id
        # votes or comments for user that owns contribution
        begin
            users = SprintTimeline.where(:id => sprint_timeline_id).joins("INNER join contributors ON sprint_timelines.contributor_id = contributors.id join users on users.id = contributors.user_id AND diff IN('vote','comment')").where("contributors.user_id != sprint_timelines.user_id").select("users.id as user_id", "sprint_timelines.id")
            return nil_for_empty users
        rescue => e
            puts e
            return nil
        end
    end

    def user_notifications_by_comments sprint_timeline_id
        # all users that commented on a specific contribution
        begin
            users = SprintTimeline.where(:id => sprint_timeline_id).joins("INNER join comments ON comments.contributor_id = sprint_timelines.contributor_id").where("comments.user_id != sprint_timelines.user_id").select("comments.user_id", "sprint_timelines.id")
            return nil_for_empty users
        rescue => e
            puts e
            return nil
        end
    end

    def user_notifications_by_votes sprint_timeline_id
        # all users that voted on a specific contribution
        begin
            users = SprintTimeline.where(:id => sprint_timeline_id).joins("INNER join votes ON votes.contributor_id = sprint_timelines.contributor_id").where("votes.user_id != sprint_timelines.user_id").select("votes.user_id", "sprint_timelines.id")
            return nil_for_empty users
        rescue => e
            puts e
            return nil
        end
    end 

    def user_notifications_for_contributors_with_winner sprint_timeline_id
        # all users that contributed to a sprint state that now has a winner
        begin
            users = SprintTimeline.where(:id => sprint_timeline_id, :diff => "winner").joins("INNER join contributors ON contributors.sprint_state_id = sprint_timelines.sprint_state_id").where("contributors.user_id != sprint_timelines.user_id").select("contributors.user_id", "sprint_timelines.id")
            return nil_for_empty users
        rescue => e
            puts e
            return nil
        end
    end

    def user_notifications_for_owner sprint_timeline_id
        # all comment and vote notifications not written by owner
        # TODO rethink ownership (anyone can create a sprint...) - also need a way to let the project owner know what's going on
        begin
            users = SprintTimeline.where(:id => sprint_timeline_id).joins("INNER join sprints ON sprint_timelines.sprint_id=sprints.id").where("sprint_timelines.user_id != sprints.user_id and sprint_timelines.diff IN('comment','vote')").select("sprints.user_id", "sprint_timelines.id")
            return nil_for_empty users
        rescue => e
            puts e
            return nil
        end
    end

    def record_user_notifications users
        begin
            users.each do |x|
                begin
                    return UserNotification.create({
                        sprint_timeline_id: x[:id],
                        user_id: x[:user_id]
                    })
                rescue => e
                    puts e
                    return nil
                end
            end
            return true
        rescue => e
            puts e
            return nil
        end
    end
end


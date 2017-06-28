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

    def log_event params 
        begin
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

    def create_project user_id, org, name
        begin
            project = Project.create({
                org: org,
                name: name,
                user_id: user_id
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

    def get_next_sprint_state sprint_state_id, sprint_states
        next_id = 0
        sprint_states.each_with_index do |s,i|
            if s == sprint_state_id
                next_id = sprint_states[i+1]
            end
        end
        return next_id
    end

    def get_sprint_state_ids_by_sprint sprint_id
        begin
            return SprintState.where(:sprint_id => sprint_id).select(:id).map(&:id)
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
end


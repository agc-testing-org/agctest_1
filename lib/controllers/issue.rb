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
            return sprint.id
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
            return sprint_state.id
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
            vote = Vote.find_or_initialize_by({
                user_id: user_id,
                sprint_state_id: sprint_state_id
            })
            new_record = vote.new_record?
            vote.update_attributes!(:contributor_id => contributor_id)
            record = vote.as_json
            record[:created] = new_record
            return record
        rescue => e
            puts e
            return nil
        end
    end

    def last_event sprint_id
        begin
            events = SprintTimeline.where(sprint_id: sprint_id)
            if events
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
            return project.id
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

    def get_idea query
        begin
            return Sprint.find_by(query)
        rescue => e
            return nil
        end
    end

    def get_sprint_states query
        begin
            response = Array.new
            SprintState.joins(:sprint).where(query).each_with_index do |ss,i|
                response[i] = ss.as_json
            end
            return response
        rescue => e
            puts e
            return nil
        end
    end

    def get_sprints query, user_id
        begin
            response = Array.new
            Sprint.where(query).each_with_index do |s,i|
                response[i] = s.as_json
                response[i][:project] = s.project.as_json
                response[i][:sprint_states] = []
                s.sprint_states.each_with_index do |ss,j|
                    response[i][:sprint_states][j] = ss.as_json
                    response[i][:sprint_states][j][:state] = ss.state.as_json 
                    response[i][:sprint_states][j][:contributors] = []
                    ss.contributors.each_with_index do |c,k|
                        response[i][:sprint_states][j][:contributors][k] = {
                            :id => c.id,
                            :created_at => c.created_at,
                            :updated_at => c.updated_at,
                            :comments => c.comments.as_json,
                            :votes => c.votes.as_json
                        }
                        if c.user_id == user_id
                            response[i][:sprint_states][j][:contributors][k][:commit] = c.commit
                            response[i][:sprint_states][j][:contributors][k][:commit_success] =  c.commit_success
                            response[i][:sprint_states][j][:contributors][k][:repo] = c.repo
                        end
                    end
                    response[i][:sprint_states][j].delete("state_id")
                    response[i][:sprint_states][j].delete("sprint_id")
                end

                response[i].delete("project_id")
            end
            return response
        rescue => e
            puts e
            return nil
        end 
    end 

    def get_events query
        begin
            response = Array.new
            SprintTimeline.where(query).each_with_index do |st,i|
                response[i] = {
                    :id => st.id,
                    :created_at => st.created_at,
                    :user => {:id => st.user.id},
                    :sprint => st.sprint.as_json,
                    :label => st.label.as_json,
                    :state => st.state.as_json,
                    :sprint_state => st.sprint_state.as_json,
                    :after => st.after
                }
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

    def get_skillsets query
        sql = ""
        if query
            puts query.inspect
            sql = "AND sprint_skillsets.sprint_id = #{query["sprint_skillsets.sprint_id"].to_i}"
        end
        begin
            return Skillset.joins("LEFT JOIN sprint_skillsets ON skillsets.id = sprint_skillsets.skillset_id #{sql}").select("skillsets.name","sprint_skillsets.active","skillsets.id").as_json
        rescue => e
            puts e
            return nil
        end
    end


    def update_skillsets sprint_id, skillset_id, active
        begin
            ss = SprintSkillset.find_or_initialize_by(:sprint_id => sprint_id, :skillset_id => skillset_id)
            ss.update_attributes!(:active => active)
            return ss
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

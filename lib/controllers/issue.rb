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
            return SprintState.includes(:state).find_by(:id => sprint_state_id)
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

    def get_sprints query, user_id
        begin
            response = Array.new
            Sprint.where(query).includes(:project).includes(:sprint_states).each_with_index do |s,i|
                response[i] = s.as_json
                response[i][:project] = s.project.as_json
                response[i][:sprint_states] = []
                s.sprint_states.includes(:state,:contributors).each_with_index do |ss,j|
                    response[i][:sprint_states][j] = ss.as_json
                    response[i][:sprint_states][j][:state] = ss.state.as_json 
                    response[i][:sprint_states][j][:contributors] = []
                    ss.contributors.includes(:comments,:votes).each_with_index do |c,k|
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
            SprintTimeline.where(query).includes(:sprint,:user,:label,:state).each_with_index do |st,i|
                response[i] = {
                    :id => st.id,
                    :created_at => st.created_at,
                    :user => {:id => st.user.id},
                    :sprint => st.sprint.as_json,
                    :label => st.label.as_json,
                    :state => st.state.as_json,
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

    def update_skillsets sprint_id, skillset_id, active
        begin
            return role = SprintSkillset.find_or_initialize_by(:sprint_id => sprint_id, :skillset_id => skillset_id).update_attributes!(:active => active)
        rescue => e
            puts e
            return nil
        end
    end

    def get_skillsets

    end

    def get #all or one, leave open to filters

    end

end 

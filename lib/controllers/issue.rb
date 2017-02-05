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

    def create_comment user_id, sprint_id, comment_id
        begin
            comment = Comment.create({
                user_id: user_id,
                sprint_id: sprint_id,
                comment_id: comment_id
            })
            return comment.id
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

    def log_event user_id, project_id, sprint_id, state_id, label_id
        after = (last_event sprint_id)
        begin
            sprint_event = SprintTimeline.create({
                user_id: project_id,
                project_id: project_id,
                sprint_id: sprint_id,
                state_id: state_id,
                label_id: label_id,
                after: after
            })
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

    def get_projects query
        begin
            return Project.where(query).as_json
        rescue => e
            puts e
            return nil
        end
    end

    def get_sprints query
        begin
            response = Array.new
            Sprint.where(query).includes(:project).includes(:sprint_states).each_with_index do |s,i|
                response[i] = s.as_json
                response[i][:project] = s.project.as_json
                response[i][:sprint_states] = []
                s.sprint_states.includes(:state).each_with_index do |ss,j|
                    response[i][:sprint_states][j] = ss.as_json
                    response[i][:sprint_states][j][:state] = ss.state.as_json 
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

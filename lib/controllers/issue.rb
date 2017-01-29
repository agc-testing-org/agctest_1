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

    def log_event sprint_id, state_id, label_id
        begin
            sprint_event = SprintTimeline.create({
                sprint_id: sprint_id,
                state_id: state_id,
                label_id: label_id
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

    def get_projects query, single
        begin
            response = Array.new
            Project.where(query).includes(:sprint_timeline).each_with_index do |p,i|
                response[i] = p.as_json
                response[i][:timeline] = p.sprint_timeline.as_json
            end
            if single 
                return response[0]
            else
                return response
            end
        rescue => e
            puts e
            return nil
        end
    end

    def get_sprints query, single
        begin
            response = Array.new
            Sprint.where(query).includes(:project).each_with_index do |s,i|
                response[i] = s.as_json
                response[i][:project] = s.project.as_json
                response[i].delete("project_id")
            end
            if single
                return response[0]
            else
                return response
            end
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

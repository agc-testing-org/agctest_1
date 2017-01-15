class Issue 
    def initialize

    end 

    def create user_id, title, description, org, repo, sha
        begin
            sprint = Sprint.create({
                user_id: user_id,
                title: title,
                description: description,
                org: org,
                repo: repo,
                sha: sha
            })
            return sprint.id
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

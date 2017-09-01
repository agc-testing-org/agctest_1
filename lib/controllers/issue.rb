class Issue 
    include Obfuscate
    def initialize

    end 

    def create user_id, title, description, project_id, job_id
        begin
            return Sprint.create({
                user_id: user_id,
                title: title.strip,
                description: description.strip,
                project_id: project_id,
                job_id: job_id
            })
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
            return SprintState.create({
                sprint_id: sprint_id,
                state_id: state_id,
                sha: sha
            })
        rescue => e
            puts e
            return nil
        end
    end

    def create_comment user_id, contributor_id, sprint_state_id, text, explain, review
        begin
            return Comment.create({
                user_id: user_id,
                sprint_state_id: sprint_state_id,
                contributor_id: contributor_id,
                text: text.strip,
                explain: explain,
                review: review
            })
        rescue => e
            puts e
            return nil
        end
    end

    def vote user_id, contributor_id, sprint_state_id, comment_id, flag
        begin
            if comment_id 
                check = {
                user_id: user_id, 
                sprint_state_id: sprint_state_id, 
                contributor_id: contributor_id, 
                comment_id: comment_id,
                flag: flag
             };
            else 
             check = { 
                user_id: user_id, 
                sprint_state_id: sprint_state_id,
                comment_id: comment_id
                } 
            end
            vote = Vote.find_or_initialize_by(check) 

            previous_record = vote.contributor_id

            if vote.id == nil
                vote.update_attributes!(:contributor_id => contributor_id)
                vote.save
                new_record = true
            elsif previous_record && previous_record != contributor_id.to_i 
                vote.update_attributes!(:contributor_id => contributor_id)
                new_record = true
            else 
                new_record = false
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

    def create_sprint_comment user_id, sprint_state_id, text
        begin
            return Comment.create({
                user_id: user_id,
                sprint_state_id: sprint_state_id,
                contributor_id: contributor_id,
                text: text.strip
            })
        rescue => e
            puts e
            return nil
        end
    end
    
    def log_event params 
        begin
            sprint_event = SprintTimeline.create(params)
            UserNotificationWorker.perform_async sprint_event.id
            return sprint_event.id
        rescue => e
            puts e
            return nil
        end
    end

    def create_project user_id, org, name, description
        begin
            return Project.create({
                org: org.strip,
                name: name.strip,
                description: (description.strip if description),
                user_id: user_id,
                preparing: true
            })
        rescue => e
            puts e
            return nil
        end
    end

    def get_projects query
        begin
            return Project.where(query)
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
            return SprintState.where(:sprint_id => sprint_id).select(:id).order(:created_at => "ASC").map(&:id)
        rescue => e
            puts e
            return nil
        end
    end

    def get_sprint_states query, user_id
        begin
            account = Account.new
            response = Array.new
            sprint_state_results = SprintState.joins(:sprint).where(query)
            sprint_state_results.each_with_index do |ss,i|
                response[i] = ss.as_json
                sprint_state = response[i]
                sprint_state_id = sprint_state['id']
                sprint_state_expires = sprint_state['expires']
                response[i][:active_contribution_id] = nil
                response[i][:contributors] = []
                ss.contributors.each_with_index do |c,k|
                    contributor_length = response[i][:contributors].length
                    if c.commit || ((sprint_state_results.length - 1) == i) # don't show empty results unless this is the current sprint_state
                        comments = c.comments.as_json
                        c.comments.each_with_index do |com,x|
                            comments[x][:user_profile] = account.get_profile com.user
                        end
                        if sprint_state_expires == nil || sprint_state_expires > Time.now.utc
                            if c[:user_id].to_i == user_id
                                response[i][:active_contribution_id] = c.id
                                response[i][:contributors][contributor_length] = {
                                    :id => c.id,
                                    :created_at => c.created_at,
                                    :updated_at => c.updated_at,
                                    :comments => comments,
                                    :votes => c.votes.as_json,
                                    :commit => c.commit,
                                    :commit_success => c.commit_success,
                                    :commit_remote => c.commit_remote,
                                    :repo => c.repo
                                }
                            end
                        end
                        if sprint_state_expires && sprint_state_expires < Time.now.utc
                            response[i][:review] = true
                            if c.commit_success == true
                                response[i][:contributors][contributor_length] = {
                                    :id => c.id,
                                    :created_at => c.created_at,
                                    :updated_at => c.updated_at,
                                    :comments => comments,
                                    :votes => c.votes.as_json
                                } 
                                if c[:user_id].to_i == user_id
                                    response[i][:active_contribution_id] = c.id
                                end
                            end
                            
                        end
                    end
                end
                sprint_comments = Comment.where(:sprint_state_id => sprint_state_id, :contributor_id => nil)
                if sprint_comments
                    sprint_state_comments = sprint_comments.as_json
                    sprint_comments.each_with_index do |l,m|
                        sprint_state_comments[m][:user_profile] = account.get_profile l.user
                    end
                    response[i][:comments] = sprint_state_comments
                end
                sprint_state_votes = Vote.where(:sprint_state_id => sprint_state_id, :contributor_id => nil).as_json
                if sprint_state_votes
                    response[i][:votes] = sprint_state_votes
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


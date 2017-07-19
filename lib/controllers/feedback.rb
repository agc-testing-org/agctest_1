class Feedback

    def initialize
        @per_page = 10
    end

    def build_feedback results
        account = Account.new
        begin
            response = []
            results.each_with_index do |result,i|
                response[i] = result.as_json
                response[i][:sprint] = result.sprint
                response[i][:project] = result.project
                response[i][:sprint_state] = result.sprint_state
                response[i][:next_sprint_state] = result.next_sprint_state
                response[i][:comment] = result.comment
                response[i][:vote] = result.vote
                response[i][:user_profile] = account.get_profile result.user
            end
            return response.as_json
        rescue => e
            puts e
            return nil
        end
    end

    def build_contribution_feedback results
        begin
            response = []
            results.each_with_index do |result,i|
                response[i] = result.as_json
                response[i][:sprint] = result.sprint_state.sprint
                response[i][:project] = result.sprint_state.sprint.project
                response[i][:sprint_state] = result.sprint_state
            end
            return response.as_json
        rescue => e
            puts e
            return nil
        end
    end

    def get_count result
        begin
            return result.except(:order,:select,:limit,:offset,:group).distinct.count
        rescue => e
            puts e
            return nil
        end
    end

    def sprint_timeline_comments_created
        begin
            return User.joins("LEFT JOIN sprint_timelines ON (users.id = sprint_timelines.user_id AND sprint_timelines.diff = 'comment') LEFT JOIN comments ON (sprint_timelines.comment_id = comments.id and sprint_timelines.comment_id IS NOT NULL)").where("sprint_timelines.diff = 'comment' OR sprint_timelines.diff IS NULL")
        rescue => e
            puts e
            return nil
        end
    end
    
    def user_comments_created_by_skillset_and_roles params
        page = (params["page"].to_i if params["page"].to_i > 0) || 1
        params_helper = ParamsHelper.new
        params = params_helper.drop_key params, "page"
        params = params_helper.assign_param_to_model params, "skillset_id", "user_skillsets"
        params = params_helper.assign_param_to_model params, "role_id", "user_roles"
        begin
            return sprint_timeline_comments_created.joins("INNER JOIN sprint_states ON sprint_states.id = comments.sprint_state_id INNER JOIN role_states ON sprint_states.state_id = role_states.state_id INNER JOIN sprint_skillsets ON sprint_skillsets.sprint_id = sprint_states.sprint_id LEFT JOIN user_skillsets ON (user_skillsets.skillset_id = sprint_skillsets.skillset_id AND user_skillsets.active = 1) LEFT JOIN user_roles ON (user_roles.role_id = role_states.role_id AND user_roles.active = 1)").where(params).select("sprint_timelines.*").group("sprint_timelines.id").order('sprint_timelines.created_at DESC').limit(@per_page).offset((page-1)*@per_page)
        rescue => e
            puts e
            return nil
        end
    end

    def sprint_timeline_comments_received
        begin
            return User.joins("LEFT JOIN contributors ON users.id = contributors.user_id LEFT JOIN sprint_timelines ON (sprint_timelines.contributor_id = contributors.id AND contributors.user_id != sprint_timelines.user_id AND sprint_timelines.diff = 'comment') LEFT JOIN comments ON (sprint_timelines.comment_id = comments.id and sprint_timelines.comment_id IS NOT NULL)").where("sprint_timelines.diff = 'comment' OR sprint_timelines.diff IS NULL")
        rescue => e
            puts e
            return nil
        end
    end

    def user_comments_received_by_skillset_and_roles params
        page = (params["page"].to_i if params["page"].to_i > 0) || 1 
        params_helper = ParamsHelper.new
        params = params_helper.drop_key params, "page"
        params = params_helper.assign_param_to_model params, "skillset_id", "user_skillsets"
        params = params_helper.assign_param_to_model params, "role_id", "user_roles"
        params = params_helper.assign_param_to_model params, "user_id", "contributors"
        begin      
            return sprint_timeline_comments_received.joins("INNER JOIN sprint_states ON sprint_states.id = comments.sprint_state_id INNER JOIN role_states ON sprint_states.state_id = role_states.state_id INNER JOIN sprint_skillsets ON sprint_skillsets.sprint_id = sprint_states.sprint_id LEFT JOIN user_skillsets ON (user_skillsets.skillset_id = sprint_skillsets.skillset_id AND user_skillsets.active = 1) LEFT JOIN user_roles ON (user_roles.role_id = role_states.role_id AND user_roles.active = 1)").where(params).select("sprint_timelines.*").group("sprint_timelines.id").order('sprint_timelines.created_at DESC').limit(@per_page).offset((page-1)*@per_page)
        rescue => e
            puts e
            return nil
        end
    end

    def sprint_timeline_votes_cast
        begin
            return User.joins("LEFT JOIN sprint_timelines ON (users.id = sprint_timelines.user_id AND sprint_timelines.diff = 'vote') LEFT JOIN votes ON (sprint_timelines.vote_id = votes.id and sprint_timelines.vote_id IS NOT NULL)").where("sprint_timelines.diff = 'vote' OR sprint_timelines.diff IS NULL")
        rescue => e
            puts e
            return nil
        end
    end

    def user_votes_cast_by_skillset_and_roles params
        page = (params["page"].to_i if params["page"].to_i > 0) || 1 
        params_helper = ParamsHelper.new
        params = params_helper.drop_key params, "page"
        params = params_helper.assign_param_to_model params, "skillset_id", "user_skillsets"
        params = params_helper.assign_param_to_model params, "role_id", "user_roles"
        begin      
            return sprint_timeline_votes_cast.joins("INNER JOIN sprint_states ON sprint_states.id = votes.sprint_state_id INNER JOIN role_states ON sprint_states.state_id = role_states.state_id INNER JOIN sprint_skillsets ON sprint_skillsets.sprint_id = sprint_states.sprint_id LEFT JOIN user_skillsets ON (user_skillsets.skillset_id = sprint_skillsets.skillset_id AND user_skillsets.active = 1) LEFT JOIN user_roles ON (user_roles.role_id = role_states.role_id AND user_roles.active = 1)").where(params).select("sprint_timelines.*").group("sprint_timelines.id").order('sprint_timelines.created_at DESC').limit(@per_page).offset((page-1)*@per_page)
        rescue => e
            puts e
            return nil
        end
    end

    def sprint_timeline_votes_received
        begin
            return User.joins("LEFT JOIN contributors ON users.id = contributors.user_id LEFT JOIN sprint_timelines ON (sprint_timelines.contributor_id = contributors.id AND contributors.user_id != sprint_timelines.user_id AND sprint_timelines.diff = 'vote') LEFT JOIN votes ON (sprint_timelines.vote_id = votes.id and sprint_timelines.vote_id IS NOT NULL)").where("sprint_timelines.diff = 'vote' OR sprint_timelines.diff IS NULL")
        rescue => e
            puts e
            return nil
        end
    end

    def user_votes_received_by_skillset_and_roles params
        page = (params["page"].to_i if params["page"].to_i > 0) || 1 
        params_helper = ParamsHelper.new
        params = params_helper.drop_key params, "page"
        params = params_helper.assign_param_to_model params, "skillset_id", "user_skillsets"
        params = params_helper.assign_param_to_model params, "role_id", "user_roles"
        params = params_helper.assign_param_to_model params, "user_id", "contributors"
        begin      
            return sprint_timeline_votes_received.joins("INNER JOIN sprint_states ON sprint_states.id = votes.sprint_state_id INNER JOIN role_states ON sprint_states.state_id = role_states.state_id INNER JOIN sprint_skillsets ON sprint_skillsets.sprint_id = sprint_states.sprint_id LEFT JOIN user_skillsets ON (user_skillsets.skillset_id = sprint_skillsets.skillset_id AND user_skillsets.active = 1) LEFT JOIN user_roles ON (user_roles.role_id = role_states.role_id AND user_roles.active = 1)").where(params).select("sprint_timelines.*").group("sprint_timelines.id").order('sprint_timelines.created_at DESC').limit(@per_page).offset((page-1)*@per_page)
        rescue => e
            puts e
            return nil
        end
    end

    def sprint_timeline_contributions
        begin
            return User.joins("LEFT JOIN sprint_timelines on users.id = sprint_timelines.contributor_id LEFT JOIN contributors ON (sprint_timelines.contributor_id = contributors.id)")
        rescue => e
            puts e
            return nil
        end
    end

    def user_contributions_created_by_skillset_and_roles params  
        page = (params["page"].to_i if params["page"].to_i > 0) || 1 
        params_helper = ParamsHelper.new
        params = params_helper.drop_key params, "page"
        params = params_helper.assign_param_to_model params, "skillset_id", "user_skillsets"
        params = params_helper.assign_param_to_model params, "role_id", "user_roles"
        params = params_helper.assign_param_to_model params, "user_id", "contributors"
        begin      
            return sprint_timeline_contributions.joins("INNER JOIN sprint_states ON contributors.sprint_state_id = sprint_states.id INNER JOIN sprints ON sprint_states.sprint_id = sprints.id INNER JOIN role_states ON sprint_states.state_id = role_states.state_id INNER JOIN sprint_skillsets ON sprint_skillsets.sprint_id = sprint_states.sprint_id LEFT JOIN user_skillsets ON (user_skillsets.skillset_id = sprint_skillsets.skillset_id AND user_skillsets.active = 1) LEFT JOIN user_roles ON (user_roles.role_id = role_states.role_id AND user_roles.active = 1)").where(params).select("contributors.*").group("contributors.id").order('contributors.created_at DESC').limit(@per_page).offset((page-1)*@per_page)
        rescue => e
            puts e
            return nil
        end
    end

    def sprint_timeline_contributions_winner
        begin
            return User.joins("LEFT JOIN sprint_timelines ON (users.id = sprint_timelines.contributor_id and sprint_timelines.diff = 'winner') LEFT JOIN contributors ON (sprint_timelines.contributor_id = contributors.id)").where("sprint_timelines.diff = 'winner' OR sprint_timelines.diff IS NULL")
        rescue => e
            puts e
            return nil
        end
    end

    def user_contributions_selected_by_skillset_and_roles params
        page = (params["page"].to_i if params["page"].to_i > 0) || 1 
        params_helper = ParamsHelper.new
        params = params_helper.drop_key params, "page"
        params = params_helper.assign_param_to_model params, "skillset_id", "user_skillsets"
        params = params_helper.assign_param_to_model params, "role_id", "user_roles"
        params = params_helper.assign_param_to_model params, "user_id", "contributors"
        begin      
            return sprint_timeline_contributions_winner.joins("INNER JOIN sprint_states ON sprint_states.id = contributors.sprint_state_id INNER JOIN role_states ON sprint_states.state_id = role_states.state_id INNER JOIN sprint_skillsets ON sprint_skillsets.sprint_id = sprint_states.sprint_id LEFT JOIN user_skillsets ON (user_skillsets.skillset_id = sprint_skillsets.skillset_id AND user_skillsets.active = 1) LEFT JOIN user_roles ON (user_roles.role_id = role_states.role_id AND user_roles.active = 1)").where(params).select("sprint_timelines.*").group("sprint_timelines.id").order('sprint_timelines.created_at DESC').limit(@per_page).offset((page-1)*@per_page)
        rescue => e
            puts e
            return nil
        end
    end
end

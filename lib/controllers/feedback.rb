class Feedback

  def initialize

  end

  def build_feedback results
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
      end
      return response.as_json
    rescue => e
        puts e
        return nil
    end
  end

  def assign_param_to_model params, key, model
      params["#{model}.#{key}"] = params[key]
      params.delete(key)
      return params
  end

  def user_comments_created_by_skillset_and_roles params
    params = assign_param_to_model params, "skillset_id", "user_skillsets"
    params = assign_param_to_model params, "role_id", "user_roles"
    begin      
      return SprintTimeline.joins("INNER JOIN comments ON (sprint_timelines.comment_id = comments.id and sprint_timelines.comment_id IS NOT NULL) INNER JOIN sprint_states ON sprint_states.id = comments.sprint_state_id INNER JOIN role_states ON sprint_states.state_id = role_states.state_id INNER JOIN sprint_skillsets ON sprint_skillsets.sprint_id = sprint_states.sprint_id LEFT JOIN user_skillsets ON (user_skillsets.skillset_id = sprint_skillsets.skillset_id AND user_skillsets.active = 1) LEFT JOIN user_roles ON (user_roles.role_id = role_states.role_id AND user_roles.active = 1)").where(params).select("sprint_timelines.*").group("sprint_timelines.id")
    rescue => e
      puts e
      return nil
    end
  end

  def user_comments_received_by_skillset_and_roles params
    user_id = params['id']
    skillset_id = params['skillset_id']
    role_id = params['role_id']
    if skillset_id && role_id
      query = SprintTimeline.joins("INNER JOIN sprint_skillsets ON sprint_skillsets.sprint_id=sprint_timelines.sprint_id INNER JOIN user_skillsets ON user_skillsets.skillset_id=sprint_skillsets.skillset_id INNER JOIN comments ON sprint_timelines.comment_id=comments.id INNER JOIN projects ON sprint_timelines.project_id=projects.id INNER JOIN contributors ON sprint_timelines.contributor_id=contributors.id INNER JOIN role_states ON comments.sprint_state_id=role_states.state_id ").where("role_states.role_id=? and user_skillsets.active=1 and user_skillsets.skillset_id=? and sprint_skillsets.active=1 and  sprint_skillsets.skillset_id=? and sprint_timelines.comment_id is not NULL and contributors.user_id=? and sprint_timelines.user_id!=contributors.user_id", role_id, skillset_id, skillset_id, user_id).select("DISTINCT sprint_timelines.id, sprint_timelines.sprint_id, sprint_timelines.project_id, sprint_timelines.next_sprint_state_id, sprint_timelines.comment_id, projects.name, projects.org")
    elsif skillset_id
      query = SprintTimeline.joins("INNER JOIN sprint_skillsets ON sprint_skillsets.sprint_id=sprint_timelines.sprint_id INNER JOIN user_skillsets ON user_skillsets.skillset_id=sprint_skillsets.skillset_id INNER JOIN comments ON sprint_timelines.comment_id=comments.id INNER JOIN projects ON sprint_timelines.project_id=projects.id INNER JOIN contributors ON sprint_timelines.contributor_id=contributors.id").where("user_skillsets.active=1 and user_skillsets.skillset_id=? and sprint_skillsets.active=1 and  sprint_skillsets.skillset_id=? and sprint_timelines.comment_id is not NULL and contributors.user_id=? and sprint_timelines.user_id!=contributors.user_id", skillset_id, skillset_id, user_id).select("DISTINCT sprint_timelines.id, sprint_timelines.sprint_id, sprint_timelines.project_id, sprint_timelines.next_sprint_state_id, sprint_timelines.comment_id, projects.name, projects.org")
    else
      query = SprintTimeline.joins("INNER JOIN comments ON sprint_timelines.comment_id=comments.id INNER JOIN role_states ON comments.sprint_state_id=role_states.state_id INNER JOIN projects ON sprint_timelines.project_id=projects.id INNER JOIN contributors ON sprint_timelines.contributor_id=contributors.id").where("role_states.role_id=? and sprint_timelines.comment_id is not NULL and contributors.user_id=? and sprint_timelines.user_id != contributors.user_id", role_id, user_id).select("DISTINCT sprint_timelines.id, sprint_timelines.sprint_id, sprint_timelines.project_id, sprint_timelines.next_sprint_state_id, sprint_timelines.comment_id, projects.name, projects.org")
    end
    begin
      response = []
      query.each_with_index do |comment, i|
        response[i] = comment.as_json
        response[i][:sprint] = comment.sprint
        response[i][:project] = comment.project
        response[i][:next_sprint_state] = comment.next_sprint_state
        response[i][:comment] = comment.comment
      end
      return response
    rescue => e
      puts e
      return nil
    end
  end

  def user_votes_cast_by_skillset_and_roles params
    user_id = params['id']
    skillset_id = params['skillset_id']
    role_id = params['role_id']
    if skillset_id && role_id
      query = SprintTimeline.joins("INNER JOIN votes ON sprint_timelines.vote_id=votes.id INNER JOIN sprint_skillsets ON sprint_skillsets.sprint_id=sprint_timelines.sprint_id INNER JOIN user_skillsets ON user_skillsets.skillset_id=sprint_skillsets.skillset_id INNER JOIN projects ON sprint_timelines.project_id=projects.id INNER JOIN role_states ON votes.sprint_state_id=role_states.state_id").where("role_states.role_id=? and user_skillsets.active=1 and user_skillsets.skillset_id=? and sprint_skillsets.active=1 and sprint_skillsets.skillset_id=? and sprint_timelines.vote_id is not NULL and sprint_timelines.user_id=?", role_id, skillset_id, skillset_id, user_id).select("DISTINCT sprint_timelines.id, sprint_timelines.sprint_id, sprint_timelines.project_id, sprint_timelines.next_sprint_state_id, sprint_timelines.vote_id, projects.name, projects.org")
    elsif skillset_id
      query = SprintTimeline.joins("INNER JOIN sprint_skillsets ON sprint_skillsets.sprint_id=sprint_timelines.sprint_id INNER JOIN user_skillsets ON user_skillsets.skillset_id=sprint_skillsets.skillset_id INNER JOIN projects ON sprint_timelines.project_id=projects.id").where("user_skillsets.active=1 and user_skillsets.skillset_id=? and sprint_skillsets.active=1 and sprint_skillsets.skillset_id=? and sprint_timelines.vote_id is not NULL and sprint_timelines.user_id=?", skillset_id, skillset_id, user_id).select("DISTINCT sprint_timelines.id, sprint_timelines.sprint_id, sprint_timelines.project_id, sprint_timelines.next_sprint_state_id, sprint_timelines.vote_id, projects.name, projects.org")
    else
      query = SprintTimeline.joins("INNER JOIN votes ON sprint_timelines.vote_id=votes.id INNER JOIN role_states ON votes.sprint_state_id=role_states.state_id INNER JOIN projects ON sprint_timelines.project_id=projects.id").where("role_states.role_id=? and sprint_timelines.vote_id is not NULL and sprint_timelines.user_id=?", role_id, user_id).select("DISTINCT sprint_timelines.id, sprint_timelines.sprint_id, sprint_timelines.project_id, sprint_timelines.next_sprint_state_id, sprint_timelines.vote_id, projects.name, projects.org")
    end
    begin
      response = []
      query.each_with_index do |vote, i|
        response[i] = vote.as_json
        response[i][:sprint] = vote.sprint
        response[i][:project] = vote.project
        response[i][:next_sprint_state] = vote.next_sprint_state
        response[i][:vote] = vote.vote
      end
      return response
    rescue => e
      puts e
      return nil
    end
  end

  def user_votes_received_by_skillset_and_roles params
    user_id = params['id']
    skillset_id = params['skillset_id']
    role_id = params['role_id']
    if skillset_id && role_id
      query = SprintTimeline.joins("INNER JOIN votes ON sprint_timelines.vote_id=votes.id INNER JOIN sprint_skillsets ON sprint_skillsets.sprint_id=sprint_timelines.sprint_id INNER JOIN user_skillsets ON user_skillsets.skillset_id=sprint_skillsets.skillset_id INNER JOIN projects ON sprint_timelines.project_id=projects.id INNER JOIN contributors ON sprint_timelines.contributor_id=contributors.id INNER JOIN role_states ON votes.sprint_state_id=role_states.state_id").where("role_states.role_id=? and user_skillsets.active=1 and user_skillsets.skillset_id=? and sprint_skillsets.active=1 and sprint_skillsets.skillset_id=? and sprint_timelines.vote_id is not NULL and contributors.user_id=? and sprint_timelines.user_id!=contributors.user_id", role_id, skillset_id, skillset_id, user_id).select("DISTINCT sprint_timelines.id, sprint_timelines.sprint_id, sprint_timelines.project_id, sprint_timelines.next_sprint_state_id, sprint_timelines.vote_id, projects.name, projects.org")
    elsif skillset_id
      query = SprintTimeline.joins("INNER JOIN sprint_skillsets ON sprint_skillsets.sprint_id=sprint_timelines.sprint_id INNER JOIN user_skillsets ON user_skillsets.skillset_id=sprint_skillsets.skillset_id INNER JOIN projects ON sprint_timelines.project_id=projects.id INNER JOIN contributors ON sprint_timelines.contributor_id=contributors.id").where("user_skillsets.active=1 and user_skillsets.skillset_id=? and sprint_skillsets.active=1 and sprint_skillsets.skillset_id=? and sprint_timelines.vote_id is not NULL and contributors.user_id=? and sprint_timelines.user_id!=contributors.user_id", skillset_id, skillset_id, user_id).select("DISTINCT sprint_timelines.id, sprint_timelines.sprint_id, sprint_timelines.project_id, sprint_timelines.next_sprint_state_id, sprint_timelines.vote_id, projects.name, projects.org")
    else
      query = SprintTimeline.joins("INNER JOIN votes ON sprint_timelines.vote_id=votes.id INNER JOIN role_states ON votes.sprint_state_id=role_states.state_id INNER JOIN projects ON sprint_timelines.project_id=projects.id INNER JOIN contributors ON sprint_timelines.contributor_id=contributors.id").where("role_states.role_id=? and sprint_timelines.vote_id is not NULL and contributors.user_id=? and sprint_timelines.user_id!=contributors.user_id", role_id, user_id).select("DISTINCT sprint_timelines.id, sprint_timelines.sprint_id, sprint_timelines.project_id, sprint_timelines.next_sprint_state_id, sprint_timelines.vote_id, projects.name, projects.org")
    end
    begin
      response = []
      query.each_with_index do |vote, i|
        response[i] = vote.as_json
        response[i][:sprint] = vote.sprint
        response[i][:project] = vote.project
        response[i][:next_sprint_state] = vote.next_sprint_state
        response[i][:vote] = vote.vote
      end
      return response
    rescue => e
      puts e
      return nil
    end
  end

  def user_contributions_created_by_skillset_and_roles params
    user_id = params['id']
    skillset_id = params['skillset_id']
    role_id = params['role_id']
    if skillset_id && role_id
      query = Contributor.joins("INNER JOIN sprint_states ON contributors.id=sprint_states.contributor_id INNER JOIN sprint_skillsets ON sprint_skillsets.sprint_id=sprint_states.sprint_id INNER JOIN user_skillsets ON user_skillsets.skillset_id=sprint_skillsets.skillset_id INNER JOIN projects ON contributors.project_id=projects.id INNER JOIN role_states ON contributors.sprint_state_id=role_states.state_id").where("role_states.role_id=? and user_skillsets.active=1 and user_skillsets.skillset_id=? and sprint_skillsets.active=1 and sprint_skillsets.skillset_id=? and contributors.user_id=?", role_id, skillset_id, skillset_id, user_id).select("DISTINCT contributors.id, sprint_states.sprint_id, contributors.project_id, contributors.sprint_state_id, sprint_states.contributor_id, projects.name, projects.org")
    elsif skillset_id
      query = Contributor.joins("INNER JOIN sprint_states ON contributors.id=sprint_states.contributor_id INNER JOIN sprint_skillsets ON sprint_skillsets.sprint_id=sprint_states.sprint_id INNER JOIN user_skillsets ON user_skillsets.skillset_id=sprint_skillsets.skillset_id INNER JOIN projects ON contributors.project_id=projects.id").where("user_skillsets.active=1 and user_skillsets.skillset_id=? and sprint_skillsets.active=1 and sprint_skillsets.skillset_id=? and contributors.user_id=?", skillset_id, skillset_id, user_id).select("DISTINCT contributors.id, sprint_states.sprint_id, contributors.project_id, contributors.sprint_state_id, sprint_states.contributor_id, projects.name, projects.org")
    else
      query = Contributor.joins("INNER JOIN sprint_states ON contributors.id=sprint_states.contributor_id INNER JOIN projects ON contributors.project_id=projects.id INNER JOIN role_states ON contributors.sprint_state_id=role_states.state_id").where("role_states.role_id=? and contributors.user_id=?", role_id, user_id).select("DISTINCT contributors.id, sprint_states.sprint_id, contributors.project_id, contributors.sprint_state_id, sprint_states.contributor_id, projects.name, projects.org")
    end
    begin
      response = []
      query.each_with_index do |contributor, i|
        response[i] = contributor.as_json
        response[i][:sprint] = contributor.sprint_state.sprint
        response[i][:project] = contributor.project
        response[i][:sprint_state] = contributor.sprint_state
      end
      return response
    rescue => e
      puts e
      return nil
    end
  end

  def user_contributions_selected_by_skillset_and_roles params
    user_id = params['id']
    skillset_id = params['skillset_id']
    role_id = params['role_id']
    if skillset_id && role_id
      query = SprintTimeline.joins("INNER JOIN sprint_states ON sprint_timelines.contributor_id=sprint_states.contributor_id INNER JOIN sprint_skillsets ON sprint_skillsets.sprint_id=sprint_states.sprint_id INNER JOIN user_skillsets ON user_skillsets.skillset_id=sprint_skillsets.skillset_id INNER JOIN projects ON sprint_timelines.project_id=projects.id INNER JOIN contributors ON contributors.id=sprint_timelines.contributor_id INNER JOIN role_states ON sprint_timelines.sprint_state_id=role_states.state_id").where("role_states.role_id=?  and user_skillsets.active=1 and user_skillsets.skillset_id=? and sprint_skillsets.active=1 and sprint_skillsets.skillset_id=? and contributors.user_id=? and sprint_timelines.user_id=contributors.user_id and sprint_timelines.diff='winner'", role_id, skillset_id, skillset_id, user_id).select("DISTINCT contributors.id, sprint_states.sprint_id, contributors.project_id, sprint_timelines.next_sprint_state_id, sprint_timelines.contributor_id, projects.name, projects.org, contributors.sprint_state_id")
    elsif skillset_id
      query = SprintTimeline.joins("INNER JOIN sprint_states ON sprint_timelines.contributor_id=sprint_states.contributor_id INNER JOIN sprint_skillsets ON sprint_skillsets.sprint_id=sprint_states.sprint_id INNER JOIN user_skillsets ON user_skillsets.skillset_id=sprint_skillsets.skillset_id INNER JOIN projects ON sprint_timelines.project_id=projects.id INNER JOIN contributors ON contributors.id=sprint_timelines.contributor_id").where("user_skillsets.active=1 and user_skillsets.skillset_id=? and sprint_skillsets.active=1 and sprint_skillsets.skillset_id=? and contributors.user_id=? and sprint_timelines.user_id=contributors.user_id and sprint_timelines.diff='winner'", skillset_id, skillset_id, user_id).select("DISTINCT contributors.id, sprint_states.sprint_id, contributors.project_id, sprint_timelines.next_sprint_state_id, projects.name, projects.org, contributors.sprint_state_id")
    else
      query = SprintTimeline.joins("INNER JOIN sprint_states ON sprint_timelines.contributor_id=sprint_states.contributor_id INNER JOIN projects ON sprint_timelines.project_id=projects.id INNER JOIN contributors ON contributors.id=sprint_timelines.contributor_id INNER JOIN role_states ON contributors.sprint_state_id=role_states.state_id").where("role_states.role_id=? and contributors.user_id=? and sprint_timelines.user_id=contributors.user_id and sprint_timelines.diff='winner'", role_id, user_id).select("DISTINCT contributors.id, sprint_states.sprint_id, contributors.project_id, sprint_timelines.next_sprint_state_id, projects.name, projects.org, contributors.sprint_state_id")
    end
    begin
      response = []
      query.each_with_index do |contributor, i|
        response[i] = contributor.as_json
        response[i][:sprint] = contributor.sprint
        response[i][:project] = contributor.project
        response[i][:next_sprint_state] = contributor.next_sprint_state
      end
      return response
    rescue => e
      puts e
      return nil
    end
  end
end

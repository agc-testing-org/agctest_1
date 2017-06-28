class Feedback

  def initialize

  end

  def user_comments_created_by_skillset_and_roles params
    user_id = params['id']
    skillset_id = params['skillset_id']
    role_id = params['role_id']
    if skillset_id && role_id
      begin
        return SprintTimeline.joins("INNER JOIN sprint_skillsets on sprint_skillsets.sprint_id=sprint_timelines.sprint_id INNER JOIN user_skillsets ON user_skillsets.skillset_id=sprint_skillsets.skillset_id INNER JOIN comments on sprint_timelines.comment_id=comments.id INNER JOIN projects on sprint_timelines.project_id=projects.id INNER JOIN role_states on sprint_timelines.state_id=role_states.state_id").where("role_states.role_id=? and user_skillsets.active=1 and user_skillsets.skillset_id=? and sprint_skillsets.active=1 and  sprint_skillsets.skillset_id=? and sprint_timelines.comment_id is not NULL and sprint_timelines.user_id=?", role_id, skillset_id, skillset_id, user_id).select("DISTINCT sprint_timelines.id, sprint_timelines.sprint_id, sprint_timelines.project_id, sprint_timelines.next_sprint_state_id, comments.text, projects.name, projects.org")
      rescue => e
        puts e
        return []
      end
    end
    if skillset_id
      begin
        return SprintTimeline.joins("INNER JOIN sprint_skillsets on sprint_skillsets.sprint_id=sprint_timelines.sprint_id INNER JOIN user_skillsets ON user_skillsets.skillset_id=sprint_skillsets.skillset_id INNER JOIN comments on sprint_timelines.comment_id=comments.id INNER JOIN projects on sprint_timelines.project_id=projects.id").where("user_skillsets.active=1 and user_skillsets.skillset_id=? and sprint_skillsets.active=1 and  sprint_skillsets.skillset_id=? and sprint_timelines.comment_id is not NULL and sprint_timelines.user_id=?", skillset_id, skillset_id, user_id).select("DISTINCT sprint_timelines.id, sprint_timelines.sprint_id, sprint_timelines.project_id, sprint_timelines.next_sprint_state_id, comments.text, projects.name, projects.org")
      rescue => e
        puts e
        return []
      end
    end
    if role_id
      begin
        return SprintTimeline.joins("INNER JOIN comments on sprint_timelines.comment_id=comments.id INNER JOIN role_states on sprint_timelines.state_id=role_states.state_id INNER JOIN projects on sprint_timelines.project_id=projects.id").where("role_states.role_id=? and sprint_timelines.comment_id is not NULL and sprint_timelines.user_id=?", role_id, user_id).select("DISTINCT sprint_timelines.id, sprint_timelines.sprint_id, sprint_timelines.project_id, sprint_timelines.sprint_state_id, comments.text, projects.name, projects.org")
      rescue => e
        puts e
        return []
      end
    end
  end

  def user_comments_received_by_skillset_and_roles params
    user_id = params['id']
    skillset_id = params['skillset_id']
    role_id = params['role_id']
    if skillset_id && role_id
      begin
        return SprintTimeline.joins("INNER JOIN sprint_skillsets on sprint_skillsets.sprint_id=sprint_timelines.sprint_id INNER JOIN user_skillsets ON user_skillsets.skillset_id=sprint_skillsets.skillset_id INNER JOIN comments on sprint_timelines.comment_id=comments.id INNER JOIN projects on sprint_timelines.project_id=projects.id INNER JOIN contributors on sprint_timelines.contributor_id=contributors.id INNER JOIN role_states on sprint_timelines.state_id=role_states.state_id ").where("role_states.role_id=? and user_skillsets.active=1 and user_skillsets.skillset_id=? and sprint_skillsets.active=1 and  sprint_skillsets.skillset_id=? and sprint_timelines.comment_id is not NULL and contributors.user_id=? and sprint_timelines.user_id!=contributors.user_id", role_id, skillset_id, skillset_id, user_id).select("DISTINCT sprint_timelines.id, sprint_timelines.sprint_id, sprint_timelines.project_id, sprint_timelines.next_sprint_state_id, comments.text, projects.name, projects.org")
      rescue => e
        puts e
        return []
      end
    end
    if skillset_id
      begin
        return SprintTimeline.joins("INNER JOIN sprint_skillsets on sprint_skillsets.sprint_id=sprint_timelines.sprint_id INNER JOIN user_skillsets ON user_skillsets.skillset_id=sprint_skillsets.skillset_id INNER JOIN comments on sprint_timelines.comment_id=comments.id INNER JOIN projects on sprint_timelines.project_id=projects.id INNER JOIN contributors on sprint_timelines.contributor_id=contributors.id").where("user_skillsets.active=1 and user_skillsets.skillset_id=? and sprint_skillsets.active=1 and  sprint_skillsets.skillset_id=? and sprint_timelines.comment_id is not NULL and contributors.user_id=? and sprint_timelines.user_id!=contributors.user_id", skillset_id, skillset_id, user_id).select("DISTINCT sprint_timelines.id, sprint_timelines.sprint_id, sprint_timelines.project_id, sprint_timelines.next_sprint_state_id, comments.text, projects.name, projects.org")
      rescue => e
        puts e
        return []
      end
    end
    if role_id
      begin
        return SprintTimeline.joins("INNER JOIN comments on sprint_timelines.comment_id=comments.id INNER JOIN role_states on sprint_timelines.state_id=role_states.state_id INNER JOIN projects on sprint_timelines.project_id=projects.id INNER JOIN contributors on sprint_timelines.contributor_id=contributors.id").where("role_states.role_id=? and sprint_timelines.comment_id is not NULL and contributors.user_id=? and sprint_timelines.user_id != contributors.user_id", role_id, user_id).select("DISTINCT sprint_timelines.id, sprint_timelines.sprint_id, sprint_timelines.project_id, sprint_timelines.sprint_state_id, comments.text, projects.name, projects.org")
      rescue => e
        puts e
        return []
      end
    end
  end

  def user_votes_cast_by_skillset_and_roles params
    user_id = params['id']
    skillset_id = params['skillset_id']
    role_id = params['role_id']
    if skillset_id && role_id
      begin
        return SprintTimeline.joins("INNER JOIN sprint_skillsets on sprint_skillsets.sprint_id=sprint_timelines.sprint_id INNER JOIN user_skillsets ON user_skillsets.skillset_id=sprint_skillsets.skillset_id INNER JOIN projects on sprint_timelines.project_id=projects.id INNER JOIN role_states on sprint_timelines.state_id=role_states.state_id").where("role_states.role_id=? and user_skillsets.active=1 and user_skillsets.skillset_id=? and sprint_skillsets.active=1 and sprint_skillsets.skillset_id=? and sprint_timelines.vote_id is not NULL and sprint_timelines.user_id=?", role_id, skillset_id, skillset_id, user_id).select("DISTINCT sprint_timelines.id, sprint_timelines.sprint_id, sprint_timelines.project_id, sprint_timelines.next_sprint_state_id, projects.name, projects.org")
      rescue => e
        puts e
        return []
      end
    end
    if skillset_id
      begin
        return SprintTimeline.joins("INNER JOIN sprint_skillsets on sprint_skillsets.sprint_id=sprint_timelines.sprint_id INNER JOIN user_skillsets ON user_skillsets.skillset_id=sprint_skillsets.skillset_id INNER JOIN projects on sprint_timelines.project_id=projects.id").where("user_skillsets.active=1 and user_skillsets.skillset_id=? and sprint_skillsets.active=1 and sprint_skillsets.skillset_id=? and sprint_timelines.vote_id is not NULL and sprint_timelines.user_id=?", skillset_id, skillset_id, user_id).select("DISTINCT sprint_timelines.id, sprint_timelines.sprint_id, sprint_timelines.project_id, sprint_timelines.next_sprint_state_id, projects.name, projects.org")
      rescue => e
        puts e
        return []
      end
    end
    if role_id
      begin
        return SprintTimeline.joins("INNER JOIN role_states on sprint_timelines.state_id=role_states.state_id INNER JOIN projects on sprint_timelines.project_id=projects.id").where("role_states.role_id=? and sprint_timelines.vote_id is not NULL and sprint_timelines.user_id=?", role_id, user_id).select("DISTINCT sprint_timelines.id, sprint_timelines.sprint_id, sprint_timelines.project_id, sprint_timelines.sprint_state_id, projects.name, projects.org")
      rescue => e
        puts e
        return []
      end
    end
  end

  def user_votes_received_by_skillset_and_roles params
    user_id = params['id']
    skillset_id = params['skillset_id']
    role_id = params['role_id']
    if skillset_id && role_id
      begin
        return SprintTimeline.joins("INNER JOIN sprint_skillsets on sprint_skillsets.sprint_id=sprint_timelines.sprint_id INNER JOIN user_skillsets ON user_skillsets.skillset_id=sprint_skillsets.skillset_id INNER JOIN projects on sprint_timelines.project_id=projects.id INNER JOIN contributors on sprint_timelines.contributor_id=contributors.id INNER JOIN role_states on sprint_timelines.state_id=role_states.state_id").where("role_states.role_id=? and user_skillsets.active=1 and user_skillsets.skillset_id=? and sprint_skillsets.active=1 and sprint_skillsets.skillset_id=? and sprint_timelines.vote_id is not NULL and contributors.user_id=? and sprint_timelines.user_id!=contributors.user_id", role_id, skillset_id, skillset_id, user_id).select("DISTINCT sprint_timelines.id, sprint_timelines.sprint_id, sprint_timelines.project_id, sprint_timelines.next_sprint_state_id, projects.name, projects.org")
      rescue => e
        puts e
        return []
      end
    end
    if skillset_id
      begin
        return SprintTimeline.joins("INNER JOIN sprint_skillsets on sprint_skillsets.sprint_id=sprint_timelines.sprint_id INNER JOIN user_skillsets ON user_skillsets.skillset_id=sprint_skillsets.skillset_id INNER JOIN projects on sprint_timelines.project_id=projects.id INNER JOIN contributors on sprint_timelines.contributor_id=contributors.id").where("user_skillsets.active=1 and user_skillsets.skillset_id=? and sprint_skillsets.active=1 and sprint_skillsets.skillset_id=? and sprint_timelines.vote_id is not NULL and contributors.user_id=? and sprint_timelines.user_id!=contributors.user_id", skillset_id, skillset_id, user_id).select("DISTINCT sprint_timelines.id, sprint_timelines.sprint_id, sprint_timelines.project_id, sprint_timelines.next_sprint_state_id, projects.name, projects.org")
      rescue => e
        puts e
        return []
      end
    end
    if role_id
      begin
        return SprintTimeline.joins("INNER JOIN role_states on sprint_timelines.state_id=role_states.state_id INNER JOIN projects on sprint_timelines.project_id=projects.id INNER JOIN contributors on sprint_timelines.contributor_id=contributors.id").where("role_states.role_id=? and sprint_timelines.vote_id is not NULL and contributors.user_id=? and sprint_timelines.user_id!=contributors.user_id", role_id, user_id).select("DISTINCT sprint_timelines.id, sprint_timelines.sprint_id, sprint_timelines.project_id, sprint_timelines.sprint_state_id, projects.name, projects.org")
      rescue => e
        puts e
        return []
      end
    end
  end

  def user_contributions_created_by_skillset_and_roles params
    user_id = params['id']
    skillset_id = params['skillset_id']
    role_id = params['role_id']
    if skillset_id && role_id
      begin
        return Contributor.joins("INNER JOIN sprint_states on contributors.id=sprint_states.contributor_id INNER JOIN sprint_skillsets on sprint_skillsets.sprint_id=sprint_states.sprint_id INNER JOIN user_skillsets ON user_skillsets.skillset_id=sprint_skillsets.skillset_id INNER JOIN projects on contributors.project_id=projects.id INNER JOIN role_states on contributors.sprint_state_id=role_states.state_id").where("role_states.role_id=? and user_skillsets.active=1 and user_skillsets.skillset_id=? and sprint_skillsets.active=1 and sprint_skillsets.skillset_id=? and contributors.user_id=?", role_id, skillset_id, skillset_id, user_id).select("DISTINCT contributors.id, sprint_states.sprint_id, contributors.project_id, contributors.sprint_state_id, projects.name, projects.org")
      rescue => e

        puts e
        return []
      end
    end
    if skillset_id
      begin
        return Contributor.joins("INNER JOIN sprint_states on contributors.id=sprint_states.contributor_id INNER JOIN sprint_skillsets on sprint_skillsets.sprint_id=sprint_states.sprint_id INNER JOIN user_skillsets ON user_skillsets.skillset_id=sprint_skillsets.skillset_id INNER JOIN projects on contributors.project_id=projects.id").where("user_skillsets.active=1 and user_skillsets.skillset_id=? and sprint_skillsets.active=1 and sprint_skillsets.skillset_id=? and contributors.user_id=?", skillset_id, skillset_id, user_id).select("DISTINCT contributors.id, sprint_states.sprint_id, contributors.project_id, contributors.sprint_state_id, projects.name, projects.org")
      rescue => e
        puts e
        return []
      end
    end
    if role_id
      begin
        return Contributor.joins("INNER JOIN sprint_states on contributors.id=sprint_states.contributor_id INNER JOIN projects on contributors.project_id=projects.id INNER JOIN role_states on contributors.sprint_state_id=role_states.state_id").where("role_states.role_id=? and contributors.user_id=?", role_id, user_id).select("DISTINCT contributors.id, sprint_states.sprint_id, contributors.project_id, contributors.sprint_state_id, projects.name, projects.org")
      rescue => e
        puts e
        return []
      end
    end

  end

  def user_contributions_selected_by_skillset_and_roles params
    user_id = params['id']
    skillset_id = params['skillset_id']
    role_id = params['role_id']
    if skillset_id && role_id
      begin
        return Contributor.joins("INNER JOIN sprint_states on contributors.id=sprint_states.contributor_id inner join sprint_skillsets on sprint_skillsets.sprint_id=sprint_states.sprint_id INNER JOIN user_skillsets ON user_skillsets.skillset_id=sprint_skillsets.skillset_id INNER JOIN projects on contributors.project_id=projects.id INNER JOIN sprint_timelines on sprint_timelines.contributor_id=contributors.id INNER JOIN role_states on contributors.sprint_state_id=role_states.state_id").where("role_states.role_id=?  and user_skillsets.active=1 and user_skillsets.skillset_id=? and sprint_skillsets.active=1 and sprint_skillsets.skillset_id=? and contributors.user_id=? and sprint_timelines.user_id=contributors.user_id and sprint_timelines.diff='winner'", role_id, skillset_id, skillset_id, user_id).select("DISTINCT contributors.id, sprint_states.sprint_id, contributors.project_id, sprint_timelines.next_sprint_state_id, projects.name, projects.org")
      rescue => e

        puts e
        return []
      end
    end
    if skillset_id
      begin
        return Contributor.joins("INNER JOIN sprint_states on contributors.id=sprint_states.contributor_id inner join sprint_skillsets on sprint_skillsets.sprint_id=sprint_states.sprint_id INNER JOIN user_skillsets ON user_skillsets.skillset_id=sprint_skillsets.skillset_id INNER JOIN projects on contributors.project_id=projects.id INNER JOIN sprint_timelines on sprint_timelines.contributor_id=contributors.id").where("user_skillsets.active=1 and user_skillsets.skillset_id=? and sprint_skillsets.active=1 and sprint_skillsets.skillset_id=? and contributors.user_id=? and sprint_timelines.user_id=contributors.user_id and sprint_timelines.diff='winner'", skillset_id, skillset_id, user_id).select("DISTINCT contributors.id, sprint_states.sprint_id, contributors.project_id, sprint_timelines.next_sprint_state_id, projects.name, projects.org")
      rescue => e
        puts e
        return []
      end
    end
    if role_id
      begin
        return Contributor.joins("INNER JOIN sprint_states on contributors.id=sprint_states.contributor_id inner join projects on contributors.project_id=projects.id INNER JOIN role_states on contributors.sprint_state_id=role_states.state_id INNER JOIN sprint_timelines on sprint_timelines.contributor_id=contributors.id").where("role_states.role_id=? and contributors.user_id=? and sprint_timelines.user_id=contributors.user_id and sprint_timelines.diff='winner'", role_id, user_id).select("DISTINCT contributors.id, sprint_states.sprint_id, contributors.project_id, contributors.sprint_state_id, projects.name, projects.org")
      rescue => e
        puts e
        return []
      end
    end
  end

end
class Organization
    include ParamsHelper 
    include NotificationsHelper

    def initialize
        @per_page = 10
    end

    def get_team id
        begin
            return Team.find_by(:id => id)
        rescue => e
            return nil
        end
    end

    def get_team_connections_requested team_id, team_plan
        begin
            contacts = []
            connections = UserConnection.joins("inner join users on user_connections.user_id = users.id INNER JOIN users contact ON contact.id = user_connections.contact_id inner join user_teams on user_connections.contact_id = user_teams.user_id").where("user_connections.team_id = ?", team_id)
            if team_plan == "recruiter" 
                account = Account.new 
                connections.select("user_connections.*, '#{team_plan}' as team_plan, users.id, users.first_name, users.email, user_teams.seat_id, user_teams.expires, contact.first_name as contact_first_name").order("user_connections.created_at DESC").each_with_index do |c,i|
                    contacts[i] = c.as_json
                    contacts[i][:user_profile] = account.get_profile c.user
                end
                return contacts 
            else # manager - don't show requestor info
                return connections.select("user_connections.id, '#{team_plan}' as team_plan,  user_connections.contact_id, user_connections.created_at, user_connections.updated_at, user_teams.seat_id, user_teams.expires, contact.first_name as contact_first_name").order("user_connections.created_at DESC").as_json
            end
        rescue => e
            puts e
            return nil
        end
    end

    def get_shares user_id, params
        account = Account.new
        shares = []
        begin
            UserTeam.where(:user_id => user_id).where(params).where(:accepted => true).order(:id => :desc).each do |user|
                row = user.as_json
                row["share_profile"] = account.get_profile user.profile
                row["share_first_name"] = user.profile.first_name
                row["sender_first_name"] = user.sender.first_name
                row["sender_last_name"] = user.sender.last_name
                row["team"] = user.team

                row.delete("token")
                shares[shares.length] = row 
            end
            return shares
        rescue => e
            puts e
        end
    end

    def get_users params
        account = Account.new
        users = []
        begin
            UserTeam.where(params).order(:id => :desc).each do |user|
                row = user.as_json
                if user.accepted
                    row["user_first_name"] = user.user.first_name
                    row["user_last_name"] = user.user.last_name
                    row["user_profile"] = account.get_profile user.user
                    row["team_comments"] = user.user.id
                    row["team_votes"] = user.user.id
                    row["team_contributors"] = user.user.id
                    row["team_comments_received"] = user.user.id
                    row["team_votes_received"] = user.user.id
                    row["team_contributors_received"] = user.user.id
                else
                    row.delete("user_id")
                end
                if user.profile
                    row["share_profile"] = account.get_profile user.profile
                    row["share_first_name"] = user.profile.first_name
                    row["share_last_name"] = user.profile.last_name
                else
                    row["share_profile"] = {:id => 0}
                end
                if user.job
                    row["job_title"] = user.job.title
                    row["job_company"] = user.job.team.company
                    row["job_team_name"] = user.job.team.name
                end
                row["sender_first_name"] = user.sender.first_name
                row["sender_last_name"] = user.sender.last_name
                row.delete("token")
                users[users.length] = row
            end
            return users
        rescue => e
            puts e
        end
    end

    def get_sprint_timeline_aggregate_counts result, params
        params = assign_param_to_model params, "seat_id", "user_teams"
        params = assign_param_to_model params, "team_id", "user_teams"
        response = []
        result.joins("INNER JOIN user_teams ON user_teams.user_id = users.id").where(params).select("count(distinct(sprint_timelines.id)) as count","users.id as user_id").group("users.id").each_with_index do |s,i|
            response[i] = {:id => s.user_id, :count => s.count}
        end
        return response
    end

    def get_contributor_aggregate_counts result, params
        params = assign_param_to_model params, "seat_id", "user_teams"
        params = assign_param_to_model params, "team_id", "user_teams"
        response = []
        result.joins("INNER JOIN user_teams ON user_teams.user_id = users.id").where(params).select("count(distinct(contributors.id)) as count","users.id as user_id").group("users.id").each_with_index do |s,i|
            response[i] = {:id => s.user_id, :count => s.count}
        end 
        return response
    end

    def create_team name, user_id, plan_id, company
        begin
            return Team.create({ name: name.strip, user_id: user_id, plan_id: plan_id, company: company })
        rescue => e
            puts e
            return nil
        end
    end

    def add_owner user_id, team_id
        begin
            return UserTeam.create({
                accepted: true,
                team_id: team_id, 
                user_id: user_id, 
                sender_id: user_id,
                seat_id: Seat.find_by(:name => "member").id
            }).as_json
        rescue => e
            puts e
            return nil
        end
    end

    def invite_member team_id, sender_id, user_id, user_email, seat_id, profile_id, job_id, expires
        begin
            return UserTeam.create({ team_id: team_id, user_id: user_id, sender_id: sender_id, user_email: (user_email.strip if user_email), token: SecureRandom.hex(32), seat_id: seat_id, profile_id: profile_id, job_id: job_id, expires: expires})
        rescue => e
            puts e
            return nil
        end
    end

    def invite_expired? invitation
        begin
            return invitation.where("updated_at >= now() - INTERVAL 1 DAY").take
        rescue => e
            puts e
            return nil
        end
    end

    def allowed_seat_types team, is_admin

        if is_admin
            return Seat.all.select(:id)
        else
            return Seat.where(:name => "member").or(Seat.where(:id => team.plan.seat.id)).or(Seat.where(:name => "share")).select(:id)
        end
    end

    def check_allowed_seats allowed, selected
        begin
            return allowed.find_by(:id => selected)
        rescue => e
            puts e
            return nil
        end
    end

    def get_team_notifications params
        team_id = params["id"].to_i
        page = (params["page"].to_i if params["page"].to_i > 0) || 1
        params = drop_key params, "page"
        puts params.inspect
        begin
            notifications = SprintTimeline.joins("inner join team_notifications ON sprint_timelines.id = team_notifications.sprint_timeline_id").where("team_notifications.team_id = ?", team_id).select("sprint_timelines.*, team_notifications.id").order('created_at DESC').limit(@per_page).offset((page-1)*@per_page)
            response = notifications_result notifications, true
            return {:meta => {:count => notifications.except(:limit,:offset,:select).count}, :data => response}
        rescue => e
            puts e
            return nil
        end
    end

    def create_job user_id, team_id, role_id, title, link, zip
        begin
            return Job.create({
                user_id: user_id,
                team_id: team_id,
                role_id: role_id,
                zip: zip,
                title: (title.strip if title),
                link: link
            })
        rescue => e
            puts e
            return nil
        end
    end

    def jobs_with_sprints jobs
        begin
            jobs_result = []
            jobs.each_with_index do |j,i|
                jobs_result[i] = j.as_json
                jobs_result[i][:role] = j.role_id
                jobs_result[i][:sprints] = j.sprints.select("sprints.*, IF(sprints.id = #{(j.sprint_id || "NULL")}, 1, 0) as selected").order("selected DESC, id DESC").as_json
                jobs_result[i][:sprints].each_with_index do |s,c|
                    jobs_result[i][:sprints][c][:project] =  s["project_id"]
                end
            end
            return jobs_result
        rescue => e
            puts e
            return nil
        end
    end

    def get_jobs query
        begin
            return Job.where(query).joins("INNER JOIN users ON users.id = jobs.user_id INNER JOIN teams ON jobs.team_id = teams.id").select("jobs.*,users.first_name as user_first_name,teams.name as team_name,teams.company as company").order(:id => "DESC")
        rescue => e
            puts e
            return nil
        end
    end

end

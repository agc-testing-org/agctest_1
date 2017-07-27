class Organization

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
        params_helper = ParamsHelper.new
        params = params_helper.assign_param_to_model params, "seat_id", "user_teams"
        params = params_helper.assign_param_to_model params, "team_id", "user_teams"
        response = []
        result.joins("INNER JOIN user_teams ON user_teams.user_id = users.id").where(params).select("count(distinct(sprint_timelines.id)) as count","users.id as user_id").group("users.id").each_with_index do |s,i|
            response[i] = {:id => s.user_id, :count => s.count}
        end
        return response
    end

    def get_contributor_aggregate_counts result, params
        params_helper = ParamsHelper.new
        params = params_helper.assign_param_to_model params, "seat_id", "user_teams"
        params = params_helper.assign_param_to_model params, "team_id", "user_teams"
        response = []
        result.joins("INNER JOIN user_teams ON user_teams.user_id = users.id").where(params).select("count(distinct(contributors.id)) as count","users.id as user_id").group("users.id").each_with_index do |s,i|
            response[i] = {:id => s.user_id, :count => s.count}
        end 
        return response
    end

    def create_team name, user_id, plan_id
        begin
            return Team.create({ name: name.strip, user_id: user_id, plan_id: plan_id }).as_json
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

    def invite_member team_id, sender_id, user_id, user_email, seat_id, profile_id
        begin
            return UserTeam.create({ team_id: team_id, user_id: user_id, sender_id: sender_id, user_email: (user_email.strip if user_email), token: SecureRandom.hex(32), seat_id: seat_id, profile_id: profile_id})
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
            return Seat.where(:name => "member").or(Seat.where(:id => team.plan.seat.id)).select(:id)
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
        team_id = params["id"]
        page = (params["page"].to_i if params["page"].to_i > 0) || 1
        params_helper = ParamsHelper.new
        params = params_helper.drop_key params, "page"
        account = Account.new
        begin
            vote_comment_winner = Notification.where({:name => "vote"}).or(Notification.where({:name => "comment"})).or(Notification.where({:name => "winner"})).select(:id).map(&:id).join(",")
            response = []
            notifications = SprintTimeline.joins("inner join user_notifications inner join user_teams INNER join contributors ON sprint_timelines.contributor_id = contributors.id INNER JOIN seats on user_teams.seat_id = seats.id").where("sprint_timelines.id=user_notifications.sprint_timeline_id and user_teams.team_id = ? and user_notifications.user_id = user_teams.user_id and user_teams.accepted = 1 and seats.name in ('sponsored', 'priority') AND sprint_timelines.notification_id IN(#{vote_comment_winner}) and contributors.user_id != sprint_timelines.user_id", team_id).select("sprint_timelines.*, user_notifications.id, user_notifications.read").order('created_at DESC').limit(@per_page).offset((page-1)*@per_page)
            notifications.each_with_index do |notification,i|
                response[i] = notification.as_json
                response[i][:talent_id] = notification.contributor.user.id
                response[i][:talent_first_name] = notification.contributor.user.first_name
                response[i][:talent_profile] = account.get_profile notification.contributor.user
                response[i][:user_id] = notification.user.id
                response[i][:user_profile] = account.get_profile notification.user
                response[i][:sprint] = notification.sprint
                response[i][:project] = notification.project
                response[i][:sprint_state] = notification.sprint_state
                response[i][:next_sprint_state] = notification.next_sprint_state
                response[i][:comment] = notification.comment
                response[i][:vote] = notification.vote
                response[i][:notification] = notification.notification
            end

            return {:meta => {:count => notifications.except(:limit,:offset,:select).count}, :data => response}

        rescue => e
            puts e
            return nil
        end
    end

end

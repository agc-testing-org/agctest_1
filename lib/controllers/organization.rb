class Organization

    def initialize

    end

    def get_team id
        begin
            return Team.find_by(:id => id)
        rescue => e
            return nil
        end
    end

    def get_users params
        begin
            account = Account.new
            users = []
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

    def get_aggregate_counts result, params
        params_helper = ParamsHelper.new
        params = params_helper.assign_param_to_model params, "seat_id", "user_teams"
        params = params_helper.assign_param_to_model params, "team_id", "user_teams"
        return result.joins("INNER JOIN user_teams ON user_teams.user_id = users.id").where(params).select("count(distinct(sprint_timelines.id)) as count","users.id").group("users.id")
    end 

    def create_team name, user_id, plan_id
        begin
            return Team.create({ name: name, user_id: user_id, plan_id: plan_id }).as_json
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

    def invite_member team_id, sender_id, user_id, user_email, seat_id
        begin
            return UserTeam.create({ team_id: team_id, user_id: user_id, sender_id: sender_id, user_email: user_email, token: SecureRandom.hex(32), seat_id: seat_id})
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

    def get_member_invite token
        begin
            return UserTeam.where(:token => token)
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
end

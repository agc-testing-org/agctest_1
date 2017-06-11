class Organization

    def initialize

    end

    def member? team_id, user_id
        begin
            return !UserTeam.find_by({team_id: team_id, user_id: user_id, accepted: true}).nil?
        rescue => e
            puts e
            return false
        end
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
            users = []
            UserTeam.where(params).order(:id => :desc).each do |user|
                row = user.as_json
                row["user_first_name"] = user.user.first_name
                row["user_last_name"] = user.user.last_name
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

    def create_team name, user_id, plan_id
        begin
            return Team.create({ name: name.downcase, user_id: user_id, plan_id: plan_id }).as_json
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
                sender_id: user_id
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

    def get_member_invite token
        begin
            return UserTeam.find_by(:token => token)
        rescue => e
            return nil
        end
    end

    def allowed_seat_types team, is_admin

        if is_admin
            return Seat.all.select(:id)
        else
            return [
                team.plan.seat_id,
                Seat.find_by(:name => "member").id,
            ]
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

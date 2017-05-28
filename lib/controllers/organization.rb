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

    def create_team name, owner_id
        begin
            return Team.create({ name: name, owner: owner_id })
        rescue => e
            puts e
            return nil
        end
    end

    def invite_member team_id, sender_id, user_id, user_email
        begin
            return UserTeam.create({ team_id: team_id, user_id: user_id, sender_id: sender_id, user_email: user_email }).as_json
        rescue => e
            puts e
            return nil
        end
    end
end

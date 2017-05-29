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
            return Team.create({ name: name, owner: owner_id }).as_json
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

    def invite_member team_id, sender_id, user_id, user_email
        begin
            invitation = UserTeam.create({ team_id: team_id, user_id: user_id, sender_id: sender_id, user_email: user_email })
            puts invitation.persisted?
            puts invitation.id
            return invitation
        rescue => e
            puts e
            return nil
        end
    end
end

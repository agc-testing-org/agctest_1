class Organization
    
    def initialize

    end

    def create_team name, owner_id
        begin
            return Team.create({ name: name, owner: owner_id })
        rescue => e
            puts e
            return nil
        end
    end
end

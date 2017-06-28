class Account

    def initialize

    end

    def linkedin_client access_token
        return LinkedIn::API.new(access_token)
    end

    def pull_linkedin_profile client
        return client.profile(fields: ["headline", "location","summary","positions"])
    end

    def post_linkedin_profile user_id, profile
        begin
            return UserProfile.create({
                user_id: user_id,
                headline: profile.headline,
                location_country_code: profile.location.country.code,
                location_name: profile.location.name
            }).id
        rescue => e
            puts e
            return nil
        end
    end

    def post_linkedin_profile_positions profile_id, profile_position
        begin
            return UserPosition.create({
                user_profile_id: profile_id,
                title: profile_position.title,
                size: profile_position.company["size"], # size symbol retrieves the obj length
                start_year: (profile_position.start_date.year if profile_position.start_date),
                end_year: (profile_position.end_date.year if profile_position.end_date),
                company: profile_position.company.name,
                industry: profile_position.company.industry
            }).id
        rescue => e
            puts e
            return nil
        end
    end

    def linkedin_code_for_token code
        begin 
            return LinkedIn::OAuth2.new.get_access_token(code).token
        rescue => e
            puts e
            return nil
        end
    end

    def github_code_for_token code
        begin
            return Octokit.exchange_code_for_token(code, ENV['INTEGRATIONS_GITHUB_CLIENT_ID'], ENV['INTEGRATIONS_GITHUB_CLIENT_SECRET'])[:access_token]
        rescue => e
            puts e
            return nil 
        end
    end

    def redis_connection
        return Redis.new(:host => ENV['INTEGRATIONS_REDIS_HOST'], :port => ENV['INTEGRATIONS_REDIS_PORT'], :db => ENV['INTEGRATIONS_REDIS_DB'])
    end

    def create_client_and_secret user_secret
        return Digest::MD5.hexdigest([ENV['INTEGRATIONS_HMAC'], user_secret].join(':').to_s)
    end

    def create_jti user_and_client_secret, iat
        return Digest::MD5.hexdigest([user_and_client_secret, iat].join(':').to_s)
    end

    def save_token type, token, value, expiration #type = auth OR user 
        redis = redis_connection
        return (redis.set("#{type}:#{token}", value) == "OK") && redis.expire("#{type}:#{token}", expiration )
    end

    def create_token user_id, user_secret, payload

        user_and_client_secret = create_client_and_secret user_secret 

        iat = Time.now.to_i
        jti = create_jti user_and_client_secret, iat

        payload = {
            # :exp => Time.now.to_i + 600,
            :iat => iat,
            :jti => jti,
            :payload => payload
        }

        return JWT.encode payload, user_and_client_secret, "HS256"
    end

    def get_key type, token
        redis = redis_connection
        return redis.get("#{type}:#{token}")
    end

    def validate_token token, user_secret
        begin
            #exp throws DecodeError by default - no need to check
            client_and_secret = create_client_and_secret user_secret
            payload, header = JWT.decode token, client_and_secret, true, { :verify_iat => true, :verify_jti => true, :algorithm => 'HS256' }
            if (payload["jti"] == (create_jti client_and_secret, payload["iat"] )) #verify_jti only checks for existence...
                return payload
            else
                return nil
            end
        rescue JWT::DecodeError => e
            puts e
            return nil
        end
    end

    def delete_token type, token #type = auth or pro
        redis = redis_connection
        return (redis.del("#{type}:#{token}") > 0)
    end

    def mail to, subject, html_body, body
        begin
            if !ENV['INTEGRATIONS_EMAIL_ADDRESS'].empty?
                Pony.mail({
                    :to => to,
                    :from => 'DoNotReply@wired7.com',
                    :bcc => 'ateam@wired7.com',
                    :via => :smtp,
                    :subject => subject,
                    :body => body,
                    :html_body => html_body,
                    :via_options => {
                        :address              => 'wiredsevencom.netfirms.com',
                        :port                 => '587',
                        :enable_starttls_auto => true,
                        :user_name            => ENV['INTEGRATIONS_EMAIL_ADDRESS'],
                        :password             => ENV['INTEGRATIONS_EMAIL_PASSWORD'],
                        :openssl_verify_mode => OpenSSL::SSL::VERIFY_NONE,
                        #:authentication       => :plain, # :plain, :login, :cram_md5, no auth by default
                        :domain               => "webmail.wired7.com" # the HELO domain provided by the client to the server
                    }
                })
            end
        rescue Exception => e
            puts e
        end
    end

    def lowercase str
        if str
            return str.downcase

        else
            return str
        end
    end

    def create email, first_name, last_name, ip
        begin
            user = User.create({
                email: email.downcase,
                first_name: (lowercase first_name),
                last_name: (lowercase last_name),
                token: SecureRandom.hex(32),
                ip: ip
            })
            return user
        rescue => e
            puts e
            return nil
        end
    end

    def valid_email email
        if email =~ /\A([^@\s]+)@((?:[-a-z0-9]+.)+[a-z]{2,})\z/i
            return true
        else
            return false
        end
    end

    def safe_string string, length #TODO - make sure we use this EVERYWHERE we accept input
        if string =~ /^[a-zA-Z0-9\-]{#{length},}$/
            return true
        else
            return false
        end
    end

    def get params
        begin
            user = User.find_by(params)
            if user
                return user
            else
                return nil
            end
        rescue => e
            puts e
            return nil
        end
    end

    def get_users params # can be used if we add search functionality later
        begin
            return User.joins("LEFT JOIN user_profiles ON user_profiles.user_id = users.id LEFT JOIN user_positions ON user_positions.user_profile_id = user_profiles.id").where(params).select(:id, :created_at, "user_profiles.location_name as location", "user_positions.title", "user_positions.industry", "user_positions.size").as_json
        rescue => e
            puts e
            return nil
        end
    end

    def update id, fields
        begin
            user = User.find_by(id: id)
            user.update(fields)
            return user.save
        rescue => e
            puts e
            return false
        end
    end

    def record_login id, ip
        begin
            login = Login.create({
                user_id: id,
                ip: ip
            })
            return login.id
        rescue => e
            puts e
            return nil
        end
    end

    def create_email user 
        begin
            mail user.email, "Wired7 Registration", "Hi #{user.first_name.capitalize},<br><br>Thanks for signing up!  We are gradually onboarding users to the service and will email you an invitation as soon as possible.<br><br><br>- Adam Cockell<br>Founder of Wired7", "Hi #{user.first_name.capitalize},\n\nThanks for signing up!  We are gradually onboarding users to the service and will email you an invitation as soon as possible.\n\n\n- Adam Cockell\nFounder of Wired7"
        rescue => e
            puts e
        end
    end

    def request_token email
        user = User.find_by(email: email)
        if user 
            user[:token] = SecureRandom.hex

            name = user.first_name
            if name 
                name = name.capitalize
            else
                name = "Hi"
            end

            mail user.email, "Wired7 Password Reset", "#{name},<br><br>We recently received a reset password request for your account.<br><br>If you'd like to continue, please click the following link:<br><br><a href='#{ENV['INTEGRATIONS_HOST']}/token/#{Digest::MD5.hexdigest(user[:email])}-#{user[:token]}'>Password Reset</a>.<br><br>This link is valid for 24 hours.<br><br>If you did not make the request, no need to take further action.<br><br><br>- The Wired7 ATeam", "#{name},\n\nWe recently received a reset password request for your account.\n\nIf you'd like to continue, please click the following link:\n#{ENV['INTEGRATIONS_HOST']}/token/#{Digest::MD5.hexdigest(user[:email])}-#{user[:token]}.\n\nThis link is valid for 24 hours.\n\nIf you did not make the request, no need to take further action.\n\n\n- The Wired7 ATeam"
            return user.save
        else
            return false
        end
    end

    def get_reset_token token
        begin
            token = token.split("-")
            return User.where("token = ? and updated_at >= now() - INTERVAL 1 DAY",token[1]).take
        rescue => e
            puts e
            return nil
        end
    end

    def confirm_user user, password, first_name, ip
        if user
            user[:first_name] = first_name
            user[:password] = BCrypt::Password.create(password)
            user[:token] = nil
            user[:protected] = false
            user[:confirmed] = true
            user[:ip] = ip
            user.save
            return user
        else
            return nil 
        end
    end

    def unlock_github_token session, github_token
        begin
            session_hash_string = get_key "session", session
            session_hash = JSON.parse(session_hash_string)
            key = session_hash["key"]                                   
            return (validate_token github_token, key)["payload"]
        rescue => e
            puts e
            return nil
        end 
    end 

    def get_roles
        begin 
            return Role.all.order(:name)
        rescue => e
            puts e
            return nil
        end
    end

    def update_role user_id, role_id, active
        begin
            return UserRole.find_or_initialize_by(:user_id => user_id, :role_id => role_id).update_attributes!(:active => active)
        rescue => e
            puts e
            return nil 
        end
    end

    def get_account_roles user_id, query
        begin            
            return Role.joins("LEFT JOIN user_roles ON user_roles.role_id = roles.id AND user_roles.user_id = #{user_id.to_i} OR user_roles.user_id is null").where(query).select("roles.id","roles.name","user_roles.active","roles.fa_icon").order(:name).as_json
        rescue => e
            puts e
            return nil
        end
    end

    def get_teams user_id
        begin 
            return Team.joins(:user_teams).where({
                "user_teams.user_id" => user_id,
                #"user_teams.accepted" => true #allow team to show for registered invites...
            })
        rescue => e
            puts e
            return nil
        end
    end

    def mail_invite invite
        mail invite.user_email, "Wired7 Invitation to #{invite.team.name} from #{invite.sender.first_name.capitalize}", "Great news,<br><br>#{invite.sender.first_name.capitalize} (#{invite.sender.email}) has invited you to the #{invite.team.name} team on Wired7!<br><br>To accept this invitation please use the following link:<br><br><a href='#{ENV['INTEGRATIONS_HOST']}/invitation/#{invite[:token]}'>Join #{invite.team.name}</a><br><br>This link is valid for 24 hours.<br><br><br>- The Wired7 ATeam", "Great news,\n\n#{invite.sender.first_name.capitalize} (#{invite.sender.email}) has invited you to the #{invite.team.name} team on Wired7!\n\nTo accept this invitation please use the following link:\n#{ENV['INTEGRATIONS_HOST']}/invitation/#{invite[:token]}\n\nThis link is valid for 24 hours.\n\n\n- The Wired7 ATeam"
    end

    def refresh_team_invite token
        begin
            invite = UserTeam.find_by(:token => token)
            if invite
                invite.token = SecureRandom.hex(32)
                invite.save
            end
            return invite
        rescue => e
            puts e
            return nil 
        end

    end

    def check_user actual_user_id, record_user_id
        if actual_user_id != nil
            return actual_user_id == record_user_id
        else
            return true
        end
    end

    def join_team token, user_id
        begin
            invite = UserTeam.where("token = ? and updated_at >= now() - INTERVAL 1 DAY",token).take
            if invite && (check_user user_id, invite.user_id)
                invite.update_attributes!({accepted: true, token: nil})
                invitation = invite.as_json
                invitation.delete("token")
                return invitation
            else
                return nil
            end
        rescue => e
            puts e
            return nil
        end
    end

    def update_user_role user_id, role_id, active
        begin
            user_role = UserRole.find_or_initialize_by(:user_id => user_id, :role_id => role_id)
            user_role.update_attributes!(:active => active)
            return {:id => user_role.role_id}
        rescue => e
            puts e
            return nil
        end
    end

    def is_owner? user_id
        begin 
            return (UserTeam.where(:user_id => user_id, :seat_id => Seat.find_by(:name => "owner").id, :accepted => true).count > 0)
        rescue => e
            puts e
            return false
        end
    end

    def sign_in email, password, ip
        begin
            user = User.find_by(email: email.downcase)
            if user && user.password
                if ((BCrypt::Password.new(user.password) == password) && user.confirmed && !user.protected)
                    return user
                else
                    return nil
                end
            else
                return nil 
            end
        rescue => e
            puts e
            return nil
        end
    end

    def get_seat user_id, team_id
        begin
            return UserTeam.find_by(:user_id => user_id, :team_id => team_id, :accepted => true).seat.name
        rescue => e
            return nil
        end
    end

    def get_user_connections query
        begin    
            return UserConnection.joins("inner join users ON user_connections.contact_id=users.id").where(query).select("user_connections.*","users.first_name").as_json
        rescue => e
            puts e
            return nil
        end
    end

    def create_connection_request user_id, contact_id
        begin
            return UserConnection.find_or_create_by({
                user_id: user_id,
                contact_id: contact_id
            }).as_json
        rescue => e
            puts e
            return nil
        end
    end

    def update_user_connections contact_id, user_id, read, confirmed
        begin
            ss = UserConnection.find_or_initialize_by(:user_id => user_id, :contact_id => contact_id)
            ss.update_attributes!(:read => read, :confirmed => confirmed)
            return ss.as_json 
        rescue => e
            puts e
            return nil
        end
    end

    def get_user_connections_requested user_id # people that request are automatically added as contacts
        begin
            return UserConnection.joins("inner join users ON user_connections.user_id=users.id AND user_connections.contact_id = #{user_id}").select("user_connections.*, users.first_name, users.email").as_json
        rescue => e
            puts e
            return nil
        end
    end

    def get_user_connections_accepted user_id
        begin      
            return UserConnection.joins("inner join users ON user_connections.contact_id=users.id AND user_connections.user_id = #{user_id}").where("user_connections.confirmed=2").select("user_connections.*, users.first_name, users.email").as_json
        rescue => e
            puts e
            return nil
        end
    end

    def get_user_notifications user_id
        begin     
            response = []
            SprintTimeline.joins("inner join user_notifications").where("sprint_timelines.id=user_notifications.sprint_timeline_id and user_notifications.user_id = ?", user_id).select("sprint_timelines.*, user_notifications.id, user_notifications.read").order('created_at DESC').each_with_index do |notification,i|
                params = {:id => notification.user_id}
                user = get_users params
                if user
                    user = user[0]
                end

                response[i] = notification.as_json
                response[i][:user_profile] = user
                response[i][:sprint] = notification.sprint
                response[i][:project] = notification.project
                response[i][:sprint_state] = notification.sprint_state
                response[i][:next_sprint_state] = notification.next_sprint_state
                response[i][:comment] = notification.comment
                response[i][:vote] = notification.vote

            end

            return response

        rescue => e
            puts e
            return nil
        end
    end

    def get_user_notifications_by_id user_id, id
        begin      
            ss = UserNotification.find_or_initialize_by(:user_id => user_id, :id => id)
            return {:id => ss.id}
        rescue => e
            puts e
            return nil
        end
    end

    def read_user_notifications user_id, id, read
        begin
            ss = UserNotification.find_or_initialize_by(:user_id => user_id, :id => id)
            ss.update_attributes!(:read => read)
            return {:id => ss.id}
        rescue => e
            puts e
            return nil
        end
    end
end

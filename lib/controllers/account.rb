class Account

    def initialize

    end

    def join_team user_id, team_id
        begin
            invite = UserTeam.find_by({ #assumes you must have an account to join...
                user_id: user_id,
                team_id: team_id
            })
            if invite
                invite.update_attributes!({accepted: true})
                return invite.as_json
            else
                return nil
            end
        rescue => e
            puts e
            return nil
        end 
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
                start_year: profile_position.start_date.year,
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

    def save_token type, token, value #type = auth OR user 
        redis = redis_connection
        return (redis.set("#{type}:#{token}", value) == "OK") && redis.expire("#{type}:#{token}", 60*60*3 ) #3 hours
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

    def create email, name, ip
        begin
            user = User.create({
                email: email.downcase,
                name: name.downcase,
                token: SecureRandom.hex(32),
                ip: ip
            })
            if user.id
                return user
            else
                return nil
            end
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

    def safe_string string, length
        if string =~ /^[a-zA-Z0-9\-]{#{length},}$/
            return true
        else
            return false
        end
    end

    def get id
        begin
            user = User.find_by(id: id)
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

    def create_email email, name, token 
        begin
            mail email, "Welcome to Wired7 #{name.capitalize}", "#{name.capitalize},<br><br>Thanks for joining us!<br><br>To continue using the service please confirm your email by opening the following link:<br><br><a href='#{ENV['INTEGRATIONS_HOST']}/token/#{Digest::MD5.hexdigest(email)}-#{token}'>Confirm My Email</a>.<br><br>This link is valid for 24 hours.<br><br><br>- The Wired7 Team", "#{name.capitalize},\n\nThanks for joining us!\n\n  To continue using the service please confirm your email by opening the following link:\n#{ENV['INTEGRATIONS_HOST']}/token/#{Digest::MD5.hexdigest(email)}-#{token}.\n\nThis link is valid for 24 hours.\n\n\n- The Wired7 Team"
        rescue => e
            puts e
        end
    end

    def request_token email
        user = User.find_by(email: email)
        if user 
            user[:token] = SecureRandom.hex
            mail user.email, "Wired7 Password Reset", "#{user.name.capitalize},<br><br>We recently received a reset password request for your account.<br><br>If you'd like to continue, please click the following link:<br><br><a href='#{ENV['INTEGRATIONS_HOST']}/token/#{Digest::MD5.hexdigest(user[:email])}-#{user[:token]}'>Password Reset</a>.<br><br>This link is valid for 24 hours.<br><br>If you did not make the request, no need to take further action.<br><br><br>- The Wired7 ATeam", "#{user.name.capitalize},\n\nWe recently received a reset password request for your account.\n\nIf you'd like to continue, please click the following link:\n#{ENV['INTEGRATIONS_HOST']}/token/#{Digest::MD5.hexdigest(user[:email])}-#{user[:token]}.\n\nThis link is valid for 24 hours.\n\nIf you did not make the request, no need to take further action.\n\n\n- The Wired7 ATeam"
            return user.save
        else
            return false
        end
    end

    def validate_reset_token token, password, ip
        token = token.split("-")
        user = User.where("token = ? and updated_at >= now() - INTERVAL 1 DAY",token[1]).take
        if user && (Digest::MD5.hexdigest(user[:email]) == token[0])
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
            return Role.all.order(:id)
        rescue => e
            puts e
            return nil
        end
    end

    def update_role user_id, role_id, active
        begin
            return role = UserRole.find_or_initialize_by(:user_id => user_id, :role_id => role_id).update_attributes!(:active => active)
        rescue => e
            puts e
            return nil 
        end
    end

    def get_account_roles user_id, query
        begin            
            return Role.joins("LEFT JOIN user_roles ON user_roles.role_id = roles.id AND user_roles.user_id = #{user_id.to_i} OR user_roles.user_id is null").where(query).select("roles.id","roles.name","user_roles.active").as_json
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

    def sign_in email, password, ip
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
    end
end

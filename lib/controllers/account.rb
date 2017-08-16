class Account
    include Obfuscate
    include ParamsHelper
    def initialize
        @per_page = 10
    end

    def linkedin_client access_token
        begin
            return LinkedIn::API.new(access_token)
        rescue => e
            puts e
            return nil
        end
    end

    def pull_linkedin_profile client
        begin
            return client.profile(fields: ["id", "public-profile-url", "headline", "location", "summary", "positions"])
        rescue => e
            puts e
            return nil
        end
    end

    def post_linkedin_profile user_id, profile
        begin
            url = profile.public_profile_url.split("/")
            username = url.last
            record = UserProfile.find_or_initialize_by({
                user_id: user_id
            })
            record.update_attributes!({
                l_id: profile.id,
                username: username, 
                headline: profile.headline,
                location_country_code: profile.location.country.code,
                location_name: profile.location.name
            })
            return record.id
        rescue => e
            puts e
            return nil
        end
    end

    def post_linkedin_profile_position profile_id, profile_position
        begin
            position = UserPosition.find_or_initialize_by({
                user_profile_id: profile_id
            })
            position.update_attributes!({
                title: profile_position.title,
                size: profile_position.company["size"], # size symbol retrieves the obj length
                start_year: (profile_position.start_date.year if profile_position.start_date),
                end_year: (profile_position.end_date.year if profile_position.end_date),
                company: profile_position.company.name,
                industry: profile_position.company.industry
            })
            return position.id
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
            return true
        rescue Exception => e
            puts e
            return false
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
                email: email.downcase.strip,
                first_name: (first_name.strip if first_name),
                last_name: (last_name.strip if last_name),
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

    def get_profile user
        if user.user_profile && user.user_profile.user_position
            return {
                :id => user.id,
                :location => user.user_profile.location_name,
                :title => user.user_profile.user_position.title,
                :industry => user.user_profile.user_position.industry,
                :size => user.user_profile.user_position.size,
                :created_at => user.created_at
            }
        else
            return {
                :id => user.id,
                :created_at => user.created_at
            }
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

    def record_login id, ip, user_agent
        begin
            login = Login.create({
                user_id: id,
                ip: ip,
                user_agent: user_agent
            })
            return login.id
        rescue => e
            puts e
            return nil
        end
    end

    def create_email email, first_name 
        body = "Thanks for signing up!  At the moment access to the service is invitation-based so that we can work more closely with users to build a great platform.  We appreciate your interest and patience, and will invite you as soon as possible."
        return mail email, "Wired7 Registration", "#{first_name},<br><br>#{body}<br><br><br>- Adam Cockell<br>Wired7 Founder", "#{first_name},\n\n#{body}\n\n\n- Adam Cockell\nWired7 Founder"
    end

    def request_token email
        user = User.find_by(email: email)
        if user 
            user[:token] = SecureRandom.hex
            user.save
            return user
        else
            return nil
        end
    end

    def mail_token name, email, token
        if !name
            name = "Hi"
        end
        link = "#{ENV['INTEGRATIONS_HOST']}/token/#{Digest::MD5.hexdigest(email)}-#{token}"
        return mail email, "Wired7 Password Reset", "#{name},<br><br>We recently received a reset password request for your account.<br><br>If you'd like to continue, please click the following link:<br><br><a href='#{link}'>#{link}</a><br><br>This link is valid for 24 hours.<br><br>If you did not make the request, no need to take further action.<br><br><br>- The Wired7 ATeam", "#{name},\n\nWe recently received a reset password request for your account.\n\nIf you'd like to continue, please click the following link:\n\n#{link}\n\nThis link is valid for 24 hours.\n\nIf you did not make the request, no need to take further action.\n\n\n- The Wired7 ATeam"
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
            user[:first_name] = first_name.strip
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

    def update_role user_id, role_id, active
        begin
            user_role = UserRole.find_or_initialize_by(:user_id => user_id, :role_id => role_id)
            user_role.update_attributes!(:active => active)
            return user_role.role
        rescue => e
            puts e
            return nil 
        end
    end

    def get_roles user_id, query
        begin            
            return Role.joins("LEFT JOIN user_roles ON user_roles.role_id = roles.id AND user_roles.user_id = #{user_id.to_i} OR user_roles.user_id is null").where(query).select("roles.id","roles.name","user_roles.active","roles.fa_icon").order(:name).as_json
        rescue => e
            puts e
            return nil
        end
    end

    def get_skillsets user_id, query
        begin
            return Skillset.joins("LEFT JOIN user_skillsets ON user_skillsets.skillset_id = skillsets.id AND user_skillsets.user_id = #{user_id.to_i} OR user_skillsets.user_id is null").where(query).select("skillsets.id","skillsets.name","user_skillsets.active").as_json
        rescue => e
            puts e
            return nil
        end
    end

    def update_skillset user_id, skillset_id, active
        begin
            ss = UserSkillset.find_or_initialize_by(:user_id => user_id, :skillset_id => skillset_id)
            ss.update_attributes!(:active => active)
            return ss.skillset
        rescue => e
            puts e
            return nil
        end
    end

    def get_active_team user_id
        begin 
            now = Time.now
            return Team.joins("inner join user_teams on teams.id = user_teams.team_id").where("user_teams.user_id = ? and user_teams.accepted = ? and expires > ?", user_id, true, now).select("teams.id").first
        rescue => e
            puts e
            return nil
        end
    end

    def get_teams user_id, params
        params = assign_param_to_model params, "seat_id", "user_teams"
        begin 
            return Team.joins(:user_teams).where({
                "user_teams.user_id" => user_id,
                "user_teams.accepted" => true #don't allow team to show for registered invites...
            }).where(params)
        rescue => e
            puts e
            return nil
        end
    end

    def mail_invite token
        invite = (get_invitation token).take
        on_team = get_seat invite[:user_id], invite.team_id
        if invite.profile_id && on_team # profile share
            link = "#{ENV['INTEGRATIONS_HOST']}/wired/#{invite.user_id}/#{invite.token}"
            return mail invite.user_email, "New Lead on Wired7 from #{invite.team.name}", "#{invite.user.first_name},<br><br>#{invite.sender.first_name} (#{invite.sender.email}) on the #{invite.team.name} team would like for you to check out a new lead.  Please use the following link to view #{invite.profile.first_name}'s profile:<br><br><a href='#{link}'>#{link}</a><br><br><br>- The Wired7 ATeam", "#{invite.user.first_name},\n\n#{invite.sender.first_name} (#{invite.sender.email}) on the #{invite.team.name} team would like for you to check out a new lead.  Please use the following link to view #{invite.profile.first_name}'s profile:\n\n#{link}\n\n\n- The Wired7 ATeam"
        else
            link = "#{ENV['INTEGRATIONS_HOST']}/invitation/#{invite[:token]}"
            return mail invite.user_email, "Wired7 Invitation to #{invite.team.name} from #{invite.sender.first_name}", "Great news,<br><br>#{invite.sender.first_name} (#{invite.sender.email}) has invited you to the #{invite.team.name} team on Wired7!<br><br>To accept this invitation please use the following link:<br><br><a href='#{link}'>#{link}</a><br><br>This link is valid for 24 hours.<br><br><br>- The Wired7 ATeam", "Great news,\n\n#{invite.sender.first_name} (#{invite.sender.email}) has invited you to the #{invite.team.name} team on Wired7!\n\nTo accept this invitation please use the following link:\n\n#{link}\n\nThis link is valid for 24 hours.\n\n\n- The Wired7 ATeam"
        end
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

    def get_invitation token
        begin 
            return UserTeam.where(:token => token)
        rescue => e
            puts e
            return nil
        end
    end

    def join_team invitation
        begin
            invite = invitation.where("updated_at >= now() - INTERVAL 1 DAY").take
            if invite 
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

    def get_seat_permissions user_id
        begin 
            res = UserTeam.where(:user_id => user_id, :accepted => true).order(:seat_id => "ASC").first
            if res
                return res.seat_id
            else
                return nil
            end
        rescue => e
            puts e
            return nil 
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
            contacts = []
            UserConnection.joins("inner join users ON user_connections.user_id = users.id inner join user_teams ON user_connections.contact_id = user_teams.user_id").where(query).select("user_connections.*","users.first_name", "user_teams.team_id").order('user_connections.created_at DESC').each_with_index do |c,i|
                contacts[i] = c.as_json
                contacts[i][:user_profile] = get_profile c.user 
            end
            return contacts
        rescue => e
            puts e
            return nil
        end
    end

    def create_connection_request user_id, contact_id, team_id, read, confirmed
        begin
            return UserConnection.find_or_create_by({
                user_id: user_id,
                contact_id: contact_id,
                team_id: team_id, 
                read: read,
                confirmed: confirmed
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
            contacts = []
            UserConnection.joins("inner join users ON user_connections.user_id=users.id AND user_connections.contact_id = #{user_id} inner join user_teams on user_connections.contact_id=user_teams.user_id").select("user_connections.*, users.first_name, users.email, user_teams.team_id").order('user_connections.created_at DESC').each_with_index do |c,i|
                contacts[i] = c.as_json
                contacts[i][:user_profile] = get_profile c.user
            end
            return contacts
        rescue => e
            puts e
            return nil
        end
    end

    def get_user_connections_accepted user_id
        begin
            contacts = []
            UserConnection.joins("inner join users ON user_connections.contact_id=users.id AND user_connections.user_id = #{user_id} inner join user_teams ON user_connections.contact_id=user_teams.user_id").where("user_connections.confirmed=2").select("user_connections.*, users.first_name, users.email, user_teams.team_id").order('user_connections.created_at DESC').each_with_index do |c,i|
                contacts[i] = c.as_json
                contacts[i][:user_profile] = get_profile c.contact
            end
            return contacts
        rescue => e
            puts e
            return nil
        end
    end

    def get_team_connections_accepted team_id
        begin   
            contacts = []
            seat_id = Seat.where({:name => "sponsored"}).or(Seat.where({:name => "priority"})).select(:id).map(&:id).join(",")
            user = UserConnection.joins("inner join user_teams on user_connections.user_id = user_teams.user_id").where("user_teams.team_id= ?", team_id).select("distinct(user_connections.user_id) as id").map(&:id).join(",") #select onlu users belong to team
            if user != ''
                UserConnection.joins("INNER JOIN users ON user_connections.contact_id = users.id INNER JOIN user_teams ON user_connections.contact_id = user_teams.user_id").where("user_connections.user_id in (#{user}) and user_teams.team_id = ? and user_connections.confirmed = 2 and user_teams.seat_id in (#{seat_id})", team_id).select("user_connections.*, users.id, users.first_name, users.email, user_teams.team_id, user_teams.seat_id").order("user_connections.created_at DESC").each_with_index do |c,i|
                    contacts[i] = c.as_json
                    contacts[i][:user_profile] = get_profile c.contact
                    contacts[i][:is_talent] = true
                end
            end
            return contacts
        rescue => e
            puts e
            return nil
        end
    end

    def get_team_connections_requested team_id
        begin   
            contacts = []
            member = []
            seat_id = Seat.where({:name => "sponsored"}).or(Seat.where({:name => "priority"})).select(:id).map(&:id).join(",")
            contact = UserConnection.joins("inner join user_teams on user_connections.contact_id = user_teams.user_id").where("user_teams.team_id= ? and user_teams.seat_id in (#{seat_id})", team_id).select("distinct(user_connections.contact_id) as id").map(&:id).join(",") #select only user who are talents in selected team
            member_temp = UserTeam.where({:team_id => team_id}).select(:user_id).map(&:user_id).each do |id|
                user_id = decrypt(id)
                member.push(user_id)
            end
            member = member.join(",")
            if contact != ''
                UserConnection.joins("INNER JOIN users ON user_connections.user_id = users.id INNER JOIN user_teams ON user_connections.contact_id = user_teams.user_id").where("user_connections.contact_id in (#{contact}) and user_connections.user_id not in (#{member})").select("user_connections.*, users.id, users.first_name, users.email, user_teams.team_id").order("user_connections.created_at DESC").each_with_index do |c,i|
                    contacts[i] = c.as_json
                    contacts[i][:user_profile] = get_profile c.contact
                end
                User.select("id, first_name").where("id in (#{contact})").each_with_index do |c, i|
                    contacts[i][:contact_first_name] = c["first_name"] #BUG NOW: if there is only one contact - and few requests to him - first_name is added only to first request
                end
            end
            return contacts
        rescue => e
            puts e
            return nil
        end
    end

    def get_user_notifications user_id, params
        page = (params["page"].to_i if params["page"].to_i > 0) || 1

        params = drop_key params, "page"
        begin     
            response = []
            notifications = SprintTimeline.joins("inner join user_notifications").where("sprint_timelines.id=user_notifications.sprint_timeline_id and user_notifications.user_id = ?", user_id).select("sprint_timelines.*, user_notifications.id, user_notifications.read").order('created_at DESC').limit(@per_page).offset((page-1)*@per_page)
            notifications.each_with_index do |notification,i| 
                response[i] = notification.as_json
                response[i][:user_profile] = get_profile notification.user
                response[i][:sprint] = notification.sprint
                response[i][:project] = notification.project
                response[i][:sprint_state] = notification.sprint_state
                response[i][:next_sprint_state] = notification.next_sprint_state
                response[i][:comment] = notification.comment
                response[i][:vote] = notification.vote
                response[i][:notification] = notification.notification

                if notification.vote && notification.vote.comment
                    response[i][:comment_vote] = notification.vote.comment
                    response[i][:user_profile_comment_vote] = get_profile notification.vote.comment.user
                end

                if notification.job
                    response[i][:job_title] = notification.job.title
                    response[i][:job_team_name] = notification.job.team.name
                    response[i][:job_company] = notification.job.company
                end
            end

            return {:meta => {:count => notifications.except(:limit,:offset,:select).count}, :data => response}

        rescue => e
            puts e
            return nil
        end
    end

    def get_user_notifications_by_id user_id, id
        begin      
            return UserNotification.find_by(:user_id => user_id, :id => id)
        rescue => e
            puts e
            return nil
        end
    end

    def get_user_notifications_settings user_id, query
        begin            
            return Notification.joins("LEFT JOIN user_notification_settings ON user_notification_settings.notification_id = notifications.id AND user_notification_settings.user_id = #{user_id.to_i} OR user_notification_settings.user_id is null").where(query).select("notifications.*","IFNull(user_notification_settings.active,1) as active,user_notification_settings.updated_at").as_json
        rescue => e
            puts e
            return nil
        end
    end

    def update_user_notifications_settings user_id, notification_id, active
        begin
            ss = UserNotificationSetting.find_or_initialize_by(:user_id => user_id, :notification_id => notification_id)
            ss.update_attributes!(:active => active)
            return {:id => ss.notification_id}
        rescue => e
            puts e
            return nil
        end
    end

    def user_profile_descriptor user_profile
        profile = "someone"
        if user_profile[:title]

            industry = ""
            if user_profile[:industry]
                industry = " in #{user_profile[:industry]}"
            end

            location = ""
            if user_profile[:location]
                location = " (#{user_profile[:location]})"
            end

            profile = "a #{user_profile[:title]}#{industry}#{location}"
        end
        return profile
    end

    def create_notification_email id, user_id
        begin
            notifications =  UserNotification.joins("INNER JOIN sprint_timelines on sprint_timelines.id=user_notifications.sprint_timeline_id INNER JOIN users on user_notifications.user_id = users.id").where("user_notifications.sprint_timeline_id = #{id} and user_notifications.user_id = #{user_id}").select("user_notifications.user_id, user_notifications.id, user_notifications.sprint_timeline_id")
            notifications.each_with_index do |notification,i| 

                user_profile = get_profile notification.sprint_timeline.user
                profile = user_profile_descriptor user_profile

                if notification.sprint_timeline.project
                    project = "#{notification.sprint_timeline.project.org}/#{notification.sprint_timeline.project.name}"
                    sprint = "#{notification.sprint_timeline.sprint.title}"
                end

                signature = "- The Wired7 ATeam"

                if notification.sprint_timeline.notification.name == "comment" #|| notification.sprint_timeline.notification.name == "vote"
                    link = "#{ENV['INTEGRATIONS_HOST']}/develop/#{notification.sprint_timeline.project.id}-#{notification.sprint_timeline.project.org}-#{notification.sprint_timeline.project.name}/sprint/#{notification.sprint_timeline.sprint.id}-#{notification.sprint_timeline.sprint.title}/state/#{notification.sprint_timeline.next_sprint_state.id}-#{notification.sprint_timeline.next_sprint_state.state.name}"
                    return mail notification.user.email, "New Wired7 #{notification.sprint_timeline.notification.name.capitalize}", "#{notification.user.first_name},<br><br>There's a new #{notification.sprint_timeline.notification.name} from #{profile} on the #{notification.sprint_timeline.next_sprint_state.state.name} phase of the <i>#{project}</i> sprint <i>#{sprint}</i><br><br>\"#{notification.sprint_timeline.comment.text}\"<br><br>Use the following link to reply:<br><br><a href='#{link}'>#{link}</a><br><br><br>#{signature}", "#{notification.user.first_name},\n\nThere's a new #{notification.sprint_timeline.notification.name} from #{profile} on the #{notification.sprint_timeline.next_sprint_state.state.name} phase of the #{project} sprint #{sprint}\n\n\"#{notification.sprint_timeline.comment.text}\"\n\nUse the following link to reply:\n\n#{link}\n\n\n#{signature}" 
                elsif notification.sprint_timeline.notification.name == "transition"
                    link = "#{ENV['INTEGRATIONS_HOST']}/develop/#{notification.sprint_timeline.project.id}-#{notification.sprint_timeline.project.org}-#{notification.sprint_timeline.project.name}/sprint/#{notification.sprint_timeline.sprint.id}-#{notification.sprint_timeline.sprint.title}/state/#{notification.sprint_timeline.sprint_state.id}-#{notification.sprint_timeline.state.name}"
                    return mail notification.user.email, "Wired7 #{notification.sprint_timeline.state.name} transition", "#{notification.user.first_name},<br><br>We've just started the #{notification.sprint_timeline.state.name} phase of the <i>#{project}</i> sprint <i>#{sprint}</i><br><br>#{notification.sprint_timeline.state.instruction}<br><br>Use the following link to join in:<br><br><a href='#{link}'>#{link}</a><br><br><br>#{signature}", "#{notification.user.first_name},\n\nWe've just started the #{notification.sprint_timeline.state.name} phase of the #{project} sprint #{sprint}\n\n#{notification.sprint_timeline.state.instruction}\n\nUse the following link to join in:\n\n#{link}\n\n\n#{signature}"
                elsif notification.sprint_timeline.notification.name == "winner"
                    link = "#{ENV['INTEGRATIONS_HOST']}/develop/#{notification.sprint_timeline.project.id}-#{notification.sprint_timeline.project.org}-#{notification.sprint_timeline.project.name}/sprint/#{notification.sprint_timeline.sprint.id}-#{notification.sprint_timeline.sprint.title}/state/#{notification.sprint_timeline.next_sprint_state.id}-#{notification.sprint_timeline.next_sprint_state.state.name}"
                    if notification.sprint_timeline.contributor.user.id == notification.user.id
                        return mail notification.user.email, "Your Wired7 Proposal Won!", "#{notification.user.first_name},<br><br>Congratulations!  Your proposal for the #{notification.sprint_timeline.next_sprint_state.state.name} phase of the <i>#{project}</i> sprint <i>#{sprint}</i> has been selected for merge!  Use the following link to check out the other proposals:<br><br><a href='#{link}'>#{link}</a><br><br><br>#{signature}", "#{notification.user.first_name},\n\nCongratulations!  Your proposal for the #{notification.sprint_timeline.next_sprint_state.state.name} phase of the #{project} sprint #{sprint} has been selected for merge!  Use the following link to check out the other proposals:\n\n#{link}\n\n\n#{signature}"
                    else
                        return mail notification.user.email, "Wired7 Proposal Selected", "#{notification.user.first_name},<br><br>A winning proposal has been selected for the #{notification.sprint_timeline.next_sprint_state.state.name} phase of the <i>#{project}</i> sprint <i>#{sprint}</i>.  Use the following link to check out all of the proposals:<br><br><a href='#{link}'>#{link}</a><br><br><br>#{signature}", "#{notification.user.first_name},\n\nA winning proposal has been selected for the #{notification.sprint_timeline.next_sprint_state.state.name} phase of the #{project} sprint #{sprint}.  Use the following link to check out all of the proposals:\n\n#{link}\n\n\n#{signature}"
                    end
                elsif notification.sprint_timeline.notification.name == "new" && notification.sprint_timeline.job_id
                    link = "#{ENV['INTEGRATIONS_HOST']}/develop/#{notification.sprint_timeline.project.id}-#{notification.sprint_timeline.project.org}-#{notification.sprint_timeline.project.name}/sprint/#{notification.sprint_timeline.sprint.id}-#{notification.sprint_timeline.sprint.title}"
                    if notification.sprint_timeline.user_id == notification.user_id 
                        #TODO - confirmation
                    else
                        return mail notification.user.email, "Wired7 Idea Pitch for #{notification.sprint_timeline.job.title} at #{notification.sprint_timeline.job.company}", "#{notification.user.first_name},<br><br>#{profile} has just proposed a new sprint idea for the #{notification.sprint_timeline.job.title} at #{notification.sprint_timeline.job.company} listing using <i>#{project}</i>:<br><br>#{sprint}<br><br>Use the following link to check it out:<br><br><a href='#{link}'>#{link}</a><br><br><br>#{signature}", "#{notification.user.first_name},\n\n#{profile} has just proposed a new sprint idea for the #{notification.sprint_timeline.job.title} at #{notification.sprint_timeline.job.company} listing using #{project}:\n\n#{sprint}\n\nUse the following link to check it out:\n\n#{link}\n\n\n#{signature}"
                    end
                elsif notification.sprint_timeline.notification.name == "job"
                    link = "#{ENV['INTEGRATIONS_HOST']}/develop/roadmap/job/#{notification.sprint_timeline.job.id}-#{notification.sprint_timeline.job.title}-at-#{notification.sprint_timeline.job.company}"
                    if notification.sprint_timeline.user_id == notification.user.id
                        #TODO send confirmation / email with information on next steps
                        return true
                    else
                        return mail notification.user.email, "#{notification.sprint_timeline.job.team.name} at #{notification.sprint_timeline.job.company} is looking for a #{notification.sprint_timeline.job.title} on Wired7", "#{notification.user.first_name},<br><br>#{notification.sprint_timeline.job.team.name} at #{notification.sprint_timeline.job.company} started a search for a #{notification.sprint_timeline.job.title}.  If you're interested, use the following link to propose and build an idea that earns the hiring manager's attention:<br><br><a href='#{link}'>#{link}</a><br><br><br>#{signature}", "#{notification.user.first_name},\n\n#{notification.sprint_timeline.job.team.name} at #{notification.sprint_timeline.job.company} started a search for a #{notification.sprint_timeline.job.title}.  If you're interested, use the following link to propose and build an idea that earns the hiring manager's attention:\n\n#{link}\n\n\n#{signature}"
                    end
                end
            end
        rescue => e
            puts e
            return false 
        end
    end
end

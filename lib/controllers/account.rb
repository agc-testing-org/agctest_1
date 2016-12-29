class Account
    def initialize

    end

    def get_provider_by_name name
        begin
            return Provider.find_by(name: name)
        rescue => e
            puts e
            return nil
        end
    end

    def code_for_token code, provider
        #graph.facebook.com/v2.8
        #api.instagram.com
        #github.com/login

        uri = URI.parse("https://#{provider.endpoint}/oauth/access_token")
        https = Net::HTTP.new(uri.host,uri.port)
        https.use_ssl = true
        req = Net::HTTP::Post.new(uri.path, initheader = {
            'Content-Type' => 'application/json',
            'Accept' => 'application/json'
        })
        req.body = {
            client_id: provider.client_id,
            client_secret: provider.client_secret,
            code: code,
            redirect_uri: "#{ENV['INTEGRATIONS_HOST']}/callback/#{provider.name}"
        }.to_json

        begin
            res = https.request(req)
            if res.code == "200"
                return JSON.parse(res.body)["access_token"]
            else
                return nil
            end
        rescue
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
            :user_id => user_id,
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

    def mail to, subject, body
        begin
            if ENV['INTEGRATIONS_EMAIL_ADDRESS']
                Pony.mail({
                    :to => to,
                    :from => 'DoNotReply@wired7.com',
                    :bcc => 'ateam@wired7.com',
                    :via => :smtp,
                    :subject => subject,
                    :body => body,
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

    def create email, name, password
        begin
            user = User.create({
                email: email,
                name: name,
                password: password
            })
            return user.id
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

    def update id, ip, jwt, tokens
        begin
            user = User.find_by(id: id)
            user.update({
                ip: ip,
                jwt: jwt,
                tokens: tokens
            })
            return user.save
        rescue => e
            puts e
            return false
        end
    end

    def record_login id, ip, provider
        begin
            login = Login.create({
                user_id: id,
                ip: ip,
                provider_id: provider
            })
            return login.id
        rescue => e
            puts e
            return nil
        end
    end

    def create_email email, name 
        begin
            mail email, "Welcome to Wired7 (Beta) #{name}", "#{name},\n\nThanks for joining us at this early stage!  We would love to hear about your experience.  Contact us at ateam@wired7.com\n\n\n- The Wired7 Team"
        rescue => e
            puts e
        end
    end
end

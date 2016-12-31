require 'sinatra'
require 'mysql2'
require 'sinatra/activerecord'
require 'json'
require 'sinatra/base'
require 'redis'
require 'jwt'
require 'net/http'
require 'open-uri'
require 'uri'
require 'bcrypt'
require 'pony'
require 'curb'

# Controllers
require_relative '../controllers/account.rb'

# Models
require_relative '../models/user.rb'
require_relative '../models/provider.rb'
require_relative '../models/login.rb'

# Workers


set :database, {
    adapter: "mysql2",  
    username: ENV['INTEGRATIONS_MYSQL_USERNAME'],
    password: ENV['INTEGRATIONS_MYSQL_PASSWORD'],
    host: ENV['INTEGRATIONS_MYSQL_HOST'],
    database: "integrations_#{ENV['RACK_ENV']}"
}  

class Integrations < Sinatra::Base

    set :public_folder, File.expand_path('integrations-client/dist')

    def protected!
        return if authorized?
        redirect to("/unauthorized.json")
    end

    def authorized?
        @session = retrieve_token
        @providers = {} 
        if @session
            account = Account.new
            @session_hash = account.get_key "session", @session
            parsed_hash = JSON.parse(@session_hash)
            if @session_hash
                @key = parsed_hash["key"]
                puts "::unlocking token"
                @jwt_hash = account.validate_token @session, @key
                if @jwt_hash
                    puts "::unlocking provider"
                    if parsed_hash["providers"]
                        provider_hash = account.validate_token parsed_hash["providers"], @key
                        if provider_hash
                            puts provider_hash.inspect
                            puts provider_hash["payload"]
                            @providers = provider_hash["payload"]
                            puts @providers.inspect
                        end
                    end
                    return true
                else
                    return false
                end
            else
                return false
            end
        else
            return false
        end
    end

    def retrieve_token
        if request.env["HTTP_AUTHORIZATION"]
            return request.env["HTTP_AUTHORIZATION"].split("Bearer ")[1]
        else
            return nil
        end
    end

    register_post = lambda do
        status 400
        response = {:success => false}
        provider = {:name => "W7", :id => 0}
        begin
            request.body.rewind
            fields = JSON.parse(request.body.read, :symbolize_names => true)
            if fields[:name].to_s.length > 1
                account = Account.new
                if (account.valid_email fields[:email]) 
                    user_id = account.create fields[:email], fields[:name], fields[:password]
                    if user_id && user_id > 0
                        user_secret = SecureRandom.hex(32) #session secret, not password
                        jwt = account.create_token user_id, user_secret, fields[:name]
                        if (account.save_token "session", jwt, {:key => user_secret}.to_json) && (account.update user_id, request.ip, jwt, nil) && (account.record_login user_id, request.ip, provider[:id])
                            response[:success] = true
                            response[:w7_token] = jwt 
                            status 200
                            account.create_email fields[:email], fields[:name]
                        else
                            status 500
                        end
                    else
                        status 201
                        response[:message] = "This email address exists in our system.  Please try to Sign In."
                    end
                else
                    response[:message] = "Please enter a valid email address."
                end
            else
                response[:message] = "Please enter a first name with more than one character (only letters, numbers, dashes)."
            end
        rescue => e
            puts e
            response[:message] = "This request is not valid.  We're looking into this."
        end
        return response.to_json
    end

    session_provider_post = lambda do
        protected!
        status 400
        response = {:success => false}

        begin
            request.body.rewind
            fields = JSON.parse(request.body.read, :symbolize_names => true)

            puts fields.inspect
            account = Account.new
            puts params.inspect
            provider = account.get_provider_by_name fields[:grant_type]
            puts provider.inspect
            if provider
                access_token = account.code_for_token(fields[:auth_code], provider)

                @providers[provider[:name]] = access_token
                puts @providers.inspect
                provider_token = account.create_token @jwt_hash["user_id"], @key, @providers 
                puts provider_token.inspect

                if (account.save_token "session", @session, {:key => @key, :providers => provider_token}.to_json) && (account.update @jwt_hash["user_id"], request.ip, @session, provider_token) && (account.record_login @jwt_hash["user_id"], request.ip, provider[:id]) 
                    status 200
                    return {:success => true, :w7_token => @session}.to_json
                else
                    return response.to_json
                end
            else
                status 500
                return response.to_json
            end
        rescue => e
            puts e
        end
    end

    session_delete = lambda do
        protected!
        account = Account.new
        if (account.delete_token "session", @session)
            status 200
            return {:success => true}.to_json
        else
            status 404
            return {:success => false}.to_json
        end
    end

    account_get = lambda do
        #    protected!
        status 200
        return {:id =>  1, :name => "adam"}.to_json
    end

    facebook_get = lambda do
        protected!
        status 200
        puts @providers.inspect        
        uri = URI.parse("https://graph.facebook.com/v2.4/me/posts?access_token=#{@providers["facebook"]}")#v2.4/shakira/insights/page_impressions?access_token=#{@providers["github"]}")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE # read into this
        data = http.get(uri.request_uri)
        puts data.body.inspect
    end

    #API
    post "/register", &register_post
    post "/session/:provider", &session_provider_post
    delete "/session", &session_delete

    get "/account", &account_get

    get "/facebook", &facebook_get


    #Ember
    get "*" do
        send_file File.expand_path('index.html',settings.public_folder)
    end
end

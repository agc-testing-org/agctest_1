require 'sinatra'
require 'mysql2'
require 'sinatra/activerecord'
require 'json'
require 'sinatra/base'
require 'redis'
require 'jwt'
require 'net/http'
require 'uri'
require 'bcrypt'
require 'pony'

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
        @jwt = retrieve_token
        if @jwt
            account = Account.new
            jwt_value = account.get_key "user", @jwt
            if jwt_value
                if account.validate_token @jwt, jwt_value
                    @user = account.get_key "user", @jwt
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
                    user_id = account.create fields[:email], fields[:name]
                    if user_id && user_id > 0
                        user_secret = SecureRandom.hex(32)
                        jwt = account.create_token user_id, user_secret, fields[:name]
                        if (account.save_token "user", jwt, user_secret) && (account.update user_id, request.ip, jwt, nil) && (account.record_login user_id, request.ip, provider[:id])
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
        status 401
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

                @user[provider[:name].to_sym] = access_token

                if (account.save_token "user", @jwt, @user) && (account.update user_id, request.ip, @jwt, @user) && (account.record_login user_id, request.ip, provider[:id]) 
                    status 200
                    return {:success => true, :w7_token => @jwt}.to_json
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
        if account.delete_token "user", @jwt
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

    #API
    post "/register", &register_post
    post "/session/:provider", &session_provider_post
    delete "/session", &session_delete

    get "/account", &account_get

    #Ember
    get "*" do
        send_file File.expand_path('index.html',settings.public_folder)
    end
end

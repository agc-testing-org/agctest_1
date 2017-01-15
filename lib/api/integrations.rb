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
require 'octokit'

# Controllers
require_relative '../controllers/account.rb'
require_relative '../controllers/issue.rb'

# Models
require_relative '../models/user.rb'
require_relative '../models/user_role.rb'
require_relative '../models/role.rb'
require_relative '../models/user.rb'
require_relative '../models/login.rb'
require_relative '../models/skillset.rb'
require_relative '../models/sprint.rb'
require_relative '../models/sprint_skillset.rb'
require_relative '../models/user_skillset.rb'
require_relative '../models/sprint_timeline.rb'
require_relative '../models/state.rb'
require_relative '../models/label.rb'
require_relative '../models/contributor.rb'

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
        if @session
            account = Account.new
            session_hash = account.get_key "session", @session
            @session_hash = JSON.parse(session_hash)
            if @session_hash
                @key = @session_hash["key"]
                puts "::unlocking token"
                @jwt_hash = account.validate_token @session, @key
                if @jwt_hash
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

    forgot_post = lambda do
        status 400
        response = {:success => false}
        begin
            request.body.rewind
            fields = JSON.parse(request.body.read, :symbolize_names => true)
            account = Account.new
            if account.valid_email fields[:email]
                 account.request_token fields[:email]
                 response[:success] = true
                 status 201
            else
                response[:message] = "Please enter a valid email address"
            end
        rescue => e
            puts e
            response[:message] = "Invalid request"
        end
        return response.to_json
    end

    register_post = lambda do
        status 400
        response = {:success => false}
        begin
            request.body.rewind
            fields = JSON.parse(request.body.read, :symbolize_names => true)
            if fields[:name].length > 1 && fields[:name].length < 30
                account = Account.new
                if (account.valid_email fields[:email]) 
                    user = account.create fields[:email], fields[:name], request.ip
                    if user # send welcome email with token
                        account.create_email fields[:email], fields[:name], user.token
                        if fields[:roles].length < 10
                            fields[:roles].each do |r|
                                account.update_role user.id, r[:id], r[:active]
                            end
                        end
                    else # user forgot OR unauthorized claim, so send reset password email
                        account.request_token fields[:email]
                    end
                    response[:success] = true
                    status 201
                else
                    response[:message] = "Please enter a valid email address."
                end
            else
                response[:message] = "Please enter a first name with more than one character (only letters, numbers, dashes)."
            end
        rescue => e
            puts e
            response[:message] = "Invalid request"
        end
        return response.to_json
    end

    reset_post = lambda do
        status 400
        response = { :success => false }
        begin
            request.body.rewind
            fields = JSON.parse(request.body.read, :symbolize_names => true)
            account = Account.new
            if fields[:token] && fields[:password]
                password_length = fields[:password].to_s.length
                if password_length > 7 && password_length < 31
                    user = account.validate_reset_token fields[:token], fields[:password], request.ip
                    if user
                        user_secret = SecureRandom.hex(32) #session secret, not password
                        jwt = account.create_token user[:id], user_secret, fields[:name]
                        if (account.save_token "session", jwt, {:key => user_secret, :user_id => user[:id]}.to_json) && (account.update user[:id], request.ip, jwt) && (account.record_login user[:id], request.ip)
                            response[:success] = true
                            response[:w7_token] = jwt 
                            status 201
                        end
                    else
                        response[:message] = "This token has expired"
                    end
                else
                    response[:message] = "Your password must be 8-30 characters in length"
                end
            else
                response[:message] = "This request is not valid"
            end
        rescue => e
            puts e
            response[:message] = "This request is not valid"
        end
        return response.to_json
    end

    login_post = lambda do
        status 400
        response = { :success => false}
        begin
            request.body.rewind
            fields = JSON.parse(request.body.read, :symbolize_names => true)
            account = Account.new

            user = account.sign_in fields[:email], fields[:password], request.ip
            if user
                user_secret = SecureRandom.hex(32) #session secret, not password
                jwt = account.create_token user[:id], user_secret, user[:name]
                if (account.save_token "session", jwt, {:key => user_secret, :user_id => user[:id]}.to_json) && (account.update user[:id], request.ip, jwt) && (account.record_login user[:id], request.ip)
                    response[:success] = true
                    response[:w7_token] = jwt
                    status 200
                end
            else
                state[:message] = "Email or password incorrect."
                status 200
            end

        rescue => e
            puts e
            response[:message] = "This request is not valid"
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

            account = Account.new

            if fields[:grant_type]
                access_token = account.code_for_token(fields[:auth_code])

                provider_token = account.create_token @jwt_hash["user_id"], @key, access_token

                if (account.save_token "session", @session, {:key => @key, :github => true}.to_json)
                    status 200
                    return {:success => true, :w7_token => @session, :github_token => provider_token}.to_json
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

    roles_get = lambda do
        account = Account.new
        return account.get_roles.to_json
    end

    sprint_post = lambda do
        protected!
        status 400
        response = {:success => false}

        puts @session_hash.inspect

        begin
            request.body.rewind
            fields = JSON.parse(request.body.read, :symbolize_names => true)

            if fields[:title] && fields[:title].length > 5
                if fields[:description] && fields[:description].length > 5
                    if fields[:org] && fields[:repo]
                        issue = Issue.new
                        res = issue.create @session_hash["user_id"], fields[:title],  fields[:description],  fields[:org],  fields[:repo],  "ABC"
                        if res
                            status 201
                            response["id"] = res
                            response[:success] = true
                        end
                    end
                end
            end
        end
        return response.to_json
    end


    #API
    post "/register", &register_post
    post "/forgot", &forgot_post
    post "/reset", &reset_post
    post "/login", &login_post
    post "/session/:provider", &session_provider_post
    delete "/session", &session_delete

    get "/roles", &roles_get

    post "/sprint", &sprint_post

    get "/account", &account_get

    #Ember
    get "*" do
        send_file File.expand_path('index.html',settings.public_folder)
    end
end

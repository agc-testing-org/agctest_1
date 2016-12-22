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

# Controllers
require_relative '../controllers/account.rb'

# Models
require_relative '../models/user.rb'
require_relative '../models/provider.rb'

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
        token = retrieve_token
        if token
            account = Account.new
            secret = account.get_secret token
            if secret
                @jwt = account.validate_token token, secret
                if @jwt
                    @github = Octokit::Client.new(:access_token => @jwt["oauth"]["github"])
                    return !@jwt.empty?
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

    session_post = lambda do
        status 400
        response = {:success => false, :message => nil}
        provider = {:name => "W7", :id => 0}
        begin
            if params[:username].to_s.length > 1
                account = Account.new
                if (account.valid_email params[:password]) #password param is email
                    user_id = account.create params[:password], params[:username]
                    if user_id && user_id > 0
                        user_secret = SecureRandom.hex(32)
                        token = account.create_token response[:success], user_secret, nil, nil, params[:username]
                        if (account.save_token token, user_secret) && (account.update user_id, request.ip, token) && (account.record_login user_id, request.ip, provider[:id])
                            response[:success] = true
                            status 200
                            account.create_email params[:password], params[:username]
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

        account = Account.new
        provider = account.get_provider_by_name params[:grant_type]
        puts provider.inspect
        if provider
            access_token = account.code_for_token(params[:auth_code], provider)

            #TODO - get old token, delete old token, then recreate and save

            token = account.create_token user_id, user_secret, access_token, provider.name, name
            if (account.save_token token, user_secret) && (account.update user_id, request.ip, token) && (account.record_login user_id, request.ip, provider.id) 
                status 200
                return {:success => true, :w7_token => token}.to_json
            else
                return response.to_json
            end

        else
            status 500
            return response.to_json
        end
    end

    session_delete = lambda do
        protected!
        account = Account.new
        if account.delete_token retrieve_token
            status 200
            return {:success => true}.to_json
        else
            status 404
            return {:success => false}.to_json
        end
    end

    #API
    post "/session", &session_post
    post "/session/:provider", &session_provider_post
    delete "/session", &session_delete

    #Ember
    get "*" do
        send_file File.expand_path('index.html',settings.public_folder)
    end
end

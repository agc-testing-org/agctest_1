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
require 'ldclient-rb'

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
require_relative '../models/project.rb'
require_relative '../models/sprint_state.rb'

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
        redirect to("/unauthorized")
    end

    def authorized?
        @session = retrieve_token
        if @session
            account = Account.new
            begin
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
            rescue => e
                puts e
                return false
            end
        else
            return false
        end
    end

    def github_authorization
        if @session_hash["github"]
            github_token = retrieve_github_token
            begin
                puts "::unlocking github token"
                account = Account.new
                access_code = (account.validate_token github_token, @key)
                return Octokit::Client.new(:access_token => access_code["payload"])
            rescue => e
                puts e
                return nil
            end
        end 
    end

    def retrieve_github_token
        if request.env["HTTP_AUTHORIZATION_GITHUB"]
            return request.env["HTTP_AUTHORIZATION_GITHUB"].split("Bearer ")[1]
        else
            return nil
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
                        if (account.save_token "session", jwt, {:key => user_secret, :id => user[:id], :name => user[:name], :admin => user[:admin]}.to_json) && (account.update user[:id], request.ip, jwt) && (account.record_login user[:id], request.ip)
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
                if (account.save_token "session", jwt, {:key => user_secret, :id => user[:id], :name => user[:name], :admin => user[:admin]}.to_json) && (account.update user[:id], request.ip, jwt) && (account.record_login user[:id], request.ip)
                    response[:success] = true
                    response[:w7_token] = jwt
                    status 200
                end
            else
                response[:message] = "Email or password incorrect."
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

                provider_token = account.create_token @session_hash["id"], @key, access_token

                if (account.save_token "session", @session, {:key => @key, :id => @session_hash["id"], :name => @session_hash["name"], :admin => @session_hash["admin"], :github => true}.to_json)
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
        protected!
        status 200
        return {:id => @session_hash["id"], :name => @session_hash["name"], :admin => @session_hash["admin"]}.to_json
    end

    roles_get = lambda do
        account = Account.new
        return account.get_roles.to_json
    end

    states_get = lambda do
        issue = Issue.new
        query = {}
        return (issue.get_states query).to_json
    end

    repositories_get = lambda do
        protected!
        github_client = github_authorization 
        puts github_client
        repositories = Array.new
        begin
            github_client.repositories.each do |repo|
                repositories[repositories.length] = {
                    :id => repo.id,
                    :name => repo.name,         
                    :owner => repo.owner.login 
                } 
            end
        rescue => e
            puts e
        end
        return repositories.to_json
    end

    projects_get = lambda do
        issue = Issue.new
        projects = issue.get_projects nil
        return projects.to_json
    end

    projects_get_by_id = lambda do
        issue = Issue.new
        query = {:id => params[:id].to_i}
        project = issue.get_projects query
        return project[0].to_json
    end

    projects_post = lambda do
        protected!
        status 400
        response = {}
        if @session_hash["admin"]
            account = Account.new
            begin
                request.body.rewind
                fields = JSON.parse(request.body.read, :symbolize_names => true)
                if fields[:org] && fields[:name]
                    issue = Issue.new
                    project = issue.create_project fields[:org], fields[:name]
                    if project 
                        response[:id] = project 
                        status 201
                    end
                end
            end
        end
        return response.to_json
    end

    sprints_get = lambda do
        issue = Issue.new
        query = {:project_id => params[:project_id].to_i }
        sprints = issue.get_sprints query
        return sprints.to_json
    end

    events_get = lambda do
        issue = Issue.new
        query = {:project_id => params[:project_id].to_i }
        events = issue.get_events query
        return events.to_json
    end

    sprints_get_by_id = lambda do
        issue = Issue.new
        query = {:project_id => params[:project_id].to_i, :id => params[:id].to_i } 
        sprint = issue.get_sprints query
        return sprint[0].to_json
    end

    sprints_post = lambda do
        protected!
        status 400
        response = {}
        begin
            request.body.rewind
            fields = JSON.parse(request.body.read, :symbolize_names => true)

            if fields[:title] && fields[:title].length > 5
                if fields[:description] && fields[:description].length > 5
                    issue = Issue.new
                    sprint = issue.create @session_hash["id"], fields[:title],  fields[:description],  params[:project_id].to_i
                    if sprint && (issue.log_event @session_hash["id"], params[:project_id].to_i, sprint, 1, nil)
                        status 201
                        response[:id] = sprint
                    end
                else
                    response[:message] = "Please enter a more detailed description"                    
                end
            else
                response[:message] = "Please enter a more descriptive title"
            end
        end
        return response.to_json
    end

    sprints_patch_by_id = lambda do
        protected!
        if @session_hash["admin"]
            status 400
            response = {}
            begin
                request.body.rewind
                fields = JSON.parse(request.body.read, :symbolize_names => true)
                if fields[:state_id]
                    issue = Issue.new
                    sprint_state = issue.create_sprint_state params[:id], fields[:state_id]
                    if sprint_state && (issue.log_event @session_hash["id"], params[:project_id].to_i, params[:id], fields[:state_id], nil)
                        status 201
                        response[:id] = sprint_state
                    end
                end
            end
        else
            status 401
            response[:message] = "You are not authorized to perform this action."
        end
        return response.to_json
    end

    sprints_post_comments = lambda do
        protected! 
        status 400
        response = {}
        begin
            request.body.rewind
            fields = JSON.parse(request.body.read, :symbolize_names => true)

            if fields[:comment] && fields[:comment].length > 1
                issue = Issue.new
                comment = issue.create_comment @session_hash["id"], params[:id], fields[:comment_id]
                if comment && (issue.log_event @session_hash["id"], params[:project_id].to_i, sprint, 1, nil)

                end
            else
                response[:message] = "Please enter a more detailed comment"
            end

        end
        return response.to_json
    end

    sprints_post_join = lambda do
        protected!
        status 400
        response = {}
        begin
            puts "HERE"
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
    get "/account", &account_get

    get "/roles", &roles_get
    get "/states", &states_get

    get "/repositories", &repositories_get

    post "/projects", &projects_post
    get "/projects", &projects_get
    get "/projects/:id", &projects_get_by_id
    post "/projects/:project_id/sprints", &sprints_post
    get "/projects/:project_id/sprints", &sprints_get
    get "/projects/:project_id/events", &events_get
    get "/projects/:project_id/sprints/:id", &sprints_get_by_id
    patch "/projects/:project_id/sprints/:id", &sprints_patch_by_id
    post "/projects/:project_id/sprints/:id/comments", &sprints_post_comments

    post "/sprint_states/:id/joins", &sprints_post_join

    get '/unauthorized' do
        status 401
        return {:message => "Looks like we went too far?"}.to_json
    end

    #Ember
    get "*" do
        send_file File.expand_path('index.html',settings.public_folder)
    end

end

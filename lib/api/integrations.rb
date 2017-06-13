require 'sinatra'
require 'mysql2'
require 'sinatra/activerecord'
require 'sinatra/strong-params'
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
require 'git'
require 'linkedin-oauth2'
require 'sidekiq'
require 'whenever'

# Controllers
require_relative '../controllers/account.rb'
require_relative '../controllers/issue.rb'
require_relative '../controllers/repo.rb'
require_relative '../controllers/organization.rb'
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
require_relative '../models/comment.rb'
require_relative '../models/vote.rb'
require_relative '../models/team.rb'
require_relative '../models/user_team.rb'
require_relative '../models/seat.rb'
require_relative '../models/plan.rb'
require_relative '../models/user_profile.rb'
require_relative '../models/user_position.rb'
require_relative '../models/notification.rb'
require_relative '../models/user_notification.rb'
require_relative '../models/user_contributor.rb'
require_relative '../models/user_connection.rb'
require_relative '../models/connection_state.rb'
 

# Workers
require_relative '../workers/notification_worker.rb'

set :database, {
    adapter: "mysql2",  
    username: ENV['INTEGRATIONS_MYSQL_USERNAME'],
    password: ENV['INTEGRATIONS_MYSQL_PASSWORD'],
    host: ENV['INTEGRATIONS_MYSQL_HOST'],
    database: "integrations_#{ENV['RACK_ENV']}"
}  

class Integrations < Sinatra::Base

    set :public_folder, File.expand_path('integrations-client/dist')

    LinkedIn.configure do |config|
        config.client_id     = ENV["INTEGRATIONS_LINKEDIN_CLIENT_ID"]
        config.client_secret = ENV["INTEGRATIONS_LINKEDIN_CLIENT_SECRET"]
        config.redirect_uri  = "#{ENV['INTEGRATIONS_HOST']}/callback/linkedin"
    end

    register Sinatra::StrongParams

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
            account = Account.new
            return account.unlock_github_token @session, retrieve_github_token 
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

    def default_to_signed field
        if field
            return field
        else
            if authorized?
                return @session_hash["id"]
            else
                status 404
                return nil
            end
        end
    end

    # API
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

    resend_invitation_post = lambda do
        status 400
        response = {:success => false}
        begin
            request.body.rewind
            fields = JSON.parse(request.body.read, :symbolize_names => true)
            account = Account.new
            invite = account.refresh_team_invite fields[:token]
            if invite
                account.mail_invite invite
            end
            response[:success] = true # always return success
            status 201
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
            if fields[:first_name].length > 1 && fields[:first_name].length < 30
                account = Account.new
                if (account.valid_email fields[:email]) 
                    user = account.create fields[:email], fields[:first_name], fields[:last_name], request.ip
                    if user && user.id 
                        account.create_email user 
                        if fields[:roles].length < 10 #accept roles from people that sign up without an invite
                            fields[:roles].each do |r|
                                account.update_role user.id, r[:id], r[:active]
                            end
                        end
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

    accept_post = lambda do
        status 400
        response = { :success => false }
        begin
            request.body.rewind
            fields = JSON.parse(request.body.read, :symbolize_names => true)
            account = Account.new
            if fields[:token] && fields[:password]
                password_length = fields[:password].to_s.length
                if password_length > 7 && password_length < 31
                    team = account.join_team fields[:token], nil
                    if team
                        user_params = {:id => team["user_id"]}
                        user = account.get user_params
                        if user
                            account.confirm_user user, fields[:password], fields[:firstName], request.ip
                            
                            owner = ((account.is_owner? user[:id]) || user[:admin])

                            user_secret = SecureRandom.hex(32) #session secret, not password
                            jwt = account.create_token user[:id], user_secret, fields[:firstName]
                            update_fields = {
                                ip: request.ip,
                                jwt: jwt
                            }
                            if (account.save_token "session", jwt, {:key => user_secret, :id => user[:id], :first_name => user[:first_name], :last_name => user[:last_name], :admin => user[:admin], :owner => owner, :github_username => user[:github_username]}.to_json) && (account.update user[:id], update_fields) && (account.record_login user[:id], request.ip)
                                response[:success] = true
                                response[:w7_token] = jwt
                                status 201
                            end
                        else
                            response[:message] = "An error has occurred"
                        end
                    else
                        response[:message] = "This token is invalid or has expired"
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

                    user = account.get_reset_token fields[:token]

                    if user
                        account.confirm_user user, fields[:password], user.first_name, request.ip

                        owner = ((account.is_owner? user[:id]) || user[:admin])

                        user_secret = SecureRandom.hex(32) #session secret, not password
                        jwt = account.create_token user[:id], user_secret, nil 
                        update_fields = {
                            ip: request.ip,
                            jwt: jwt
                        }
                        if (account.save_token "session", jwt, {:key => user_secret, :id => user[:id], :first_name => user[:first_name], :last_name => user[:last_name], :admin => user[:admin], :owner => owner, :github_username => user[:github_username]}.to_json) && (account.update user[:id], update_fields) && (account.record_login user[:id], request.ip)
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

                owner = ((account.is_owner? user[:id]) || user[:admin]) 

                user_secret = SecureRandom.hex(32) #session secret, not password
                jwt = account.create_token user[:id], user_secret, user[:name]
                update_fields = {
                    ip: request.ip, 
                    jwt: jwt                        
                }
                if (account.save_token "session", jwt, {:key => user_secret, :id => user[:id], :first_name => user[:first_name], :last_name => user[:last_name], :admin => user[:admin], :owner => owner, :github_username => user[:github_username]}.to_json) && (account.update user[:id], update_fields) && (account.record_login user[:id], request.ip)
                    response[:success] = true
                    response[:w7_token] = jwt
                    status 200
                end
            else
                response[:message] = "Email or password incorrect."
                status 401
            end
        rescue => e
            puts e
            response[:message] = "This request is not valid"
        end
        return response.to_json
    end

    session_provider_linkedin_post = lambda do
        protected!
        status 400

        response = {:success => false, :w7_token => @session}.to_json

        begin 
            request.body.rewind
            fields = JSON.parse(request.body.read, :symbolize_names => true)

            account = Account.new 
            access_token = account.linkedin_code_for_token(fields[:auth_code])

            #Skip storing linkedin token.. 
            #for now just pull what we can from the service and drop the token

            linkedin = (account.linkedin_client access_token)
            pulled = account.pull_linkedin_profile linkedin

            if pulled

                profile_id = account.post_linkedin_profile @session_hash["id"], pulled

                if profile_id && (account.post_linkedin_profile_positions profile_id, pulled.positions.all[0]) #only current position available for now
                    status 201 
                    return {:success => true, :w7_token => @session}.to_json
                else
                    return response.to_json
                end
            else
                return response.to_json
            end

        rescue => e
            puts e
            return response.to_json
        end

    end

    session_provider_github_post = lambda do
        protected!
        status 400
        response = {:success => false}

        begin
            request.body.rewind
            fields = JSON.parse(request.body.read, :symbolize_names => true)

            account = Account.new

            if fields[:grant_type]
                access_token = account.github_code_for_token(fields[:auth_code])

                repo = Repo.new
                github = (repo.github_client access_token)
                username = github.login

                provider_token = account.create_token @session_hash["id"], @key, access_token
                update_fields = {
                    github_username: username 
                }  
                if (account.save_token "session", @session, {:key => @key, :id => @session_hash["id"], :first_name => @session_hash["first_name"], :last_name => @session_hash["last_name"], :admin => @session_hash["admin"], :owner => @session_hash["owner"], :github => true, :github_username => username}.to_json) && (account.update @session_hash["id"], update_fields)
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

    session_get = lambda do
        protected!
        status 200
        return {:id => @session_hash["id"], :first_name => @session_hash["first_name"], :last_name => @session_hash["last_name"], :admin => @session_hash["admin"], :owner => @session_hash["owner"], :github => @session_hash["github"], :github_username => @session_hash["github_username"]}.to_json
    end

    users_get_by_id = lambda do
        status 404
        account = Account.new
        user = account.get_users params
        if user[0]
            status 200
            return user[0].to_json
        else
            return {}.to_json
        end
    end

    users_get_by_me = lambda do
        protected!
        redirect to("/users/#{@session_hash["id"]}")
    end

    users_roles_get = lambda do
        account = Account.new
        return (account.get_account_roles params[:user_id], {}).to_json
    end

    users_roles_get_by_me = lambda do
        protected!
        redirect to("/users/#{@session_hash["id"]}/roles")
    end

    users_roles_get_by_role = lambda do
        account = Account.new
        query = {:id => params[:role_id]}
        return (account.get_account_roles params[:user_id], query)[0].to_json
    end

    users_roles_patch_by_id = lambda do
        protected!
        status 401
        response = {}
        user_id=params[:user_id]
        if @session_hash["id"].to_i.equal?(user_id.to_i)
            status 400
            begin
                request.body.rewind
                fields = JSON.parse(request.body.read, :symbolize_names => true)
                if params[:user_id] && params[:role_id] && fields.key?(:active)
                    account = Account.new
                    response = (account.update_user_role user_id, params[:role_id], fields[:active])
                    if response
                        status 201
                    end
                end
            rescue => e
                puts e
            end
        end
        return response.to_json    
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

    skillsets_get = lambda do
        issue = Issue.new
        return (issue.get_skillsets).to_json
    end

    plans_get = lambda do
        return (Plan.all.as_json).to_json
    end

    seats_get = lambda do
        return (Seat.all.as_json).to_json
    end

    sprint_skillsets_get = lambda do
        issue = Issue.new
        return (issue.get_sprint_skillsets params[:sprint_id], {}).to_json
    end

    sprint_skillsets_get_by_skillset = lambda do
        issue = Issue.new
        query = {:id => params[:skillset_id]}
        return (issue.get_sprint_skillsets params[:sprint_id], query)[0].to_json
    end

    sprint_skillsets_patch = lambda do
        protected!
        status 401          
        response = {}  
        if @session_hash["admin"]
            status 400
            begin
                request.body.rewind
                fields = JSON.parse(request.body.read, :symbolize_names => true)
                if params[:sprint_id] && params[:skillset_id]
                    issue = Issue.new
                    response = (issue.update_skillsets params[:sprint_id], params[:skillset_id], fields[:active])           
                    if response
                        status 201
                    end
                end
            rescue => e
                puts e
            end
        end
        return response.to_json
    end

    users_skillsets_get = lambda do
        issue = Issue.new
        return (issue.get_user_skillsets params[:user_id], {}).to_json
    end

    users_skillsets_get_by_me = lambda do
        protected!
        redirect to("/users/#{@session_hash["id"]}/skillsets")
    end

    users_skillsets_get_by_skillset = lambda do
        issue = Issue.new
        query = {:id => params[:skillset_id]}
        return (issue.get_user_skillsets params[:user_id], query)[0].to_json
    end

    users_skillsets_patch = lambda do
        protected!
        status 401
        response = {}
        user_id=params[:user_id]
        if @session_hash["id"].to_i.equal?(user_id.to_i)
            status 400
            begin
                request.body.rewind
                fields = JSON.parse(request.body.read, :symbolize_names => true)
                if params[:user_id] && params[:skillset_id] && fields.key?(:active)
                    issue = Issue.new
                    response = (issue.update_user_skillsets user_id, params[:skillset_id], fields[:active])
                    if response
                        status 201
                    end
                end
            rescue => e
                puts e
            end
        end
        return response.to_json
    end


    repositories_get = lambda do
        protected!
        repo = Repo.new
        github = (repo.github_client github_authorization)
        repositories = Array.new
        begin
            github.repositories.each do |repo|
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
        if projects
            status 200
            return projects.to_json
        else
            return {}
        end
    end

    projects_get_by_id = lambda do
        status 404
        issue = Issue.new
        project = issue.get_projects params
        if project[0]
            status 200
            return project[0].to_json
        else
            return {}
        end
    end

    projects_post = lambda do
        protected!
        status 400
        if @session_hash["admin"]
            response = {}
            account = Account.new
            begin
                request.body.rewind
                fields = JSON.parse(request.body.read, :symbolize_names => true)
                if fields[:org] && fields[:name]
                    issue = Issue.new
                    project = issue.create_project fields[:org], fields[:name]
                    if project 
                        response = project 
                        status 201
                    end
                end
            end
            return response.to_json
        else
            redirect to("/unauthorized") 
        end
    end

    teams_get = lambda do
        protected!
        account = Account.new
        teams = account.get_teams @session_hash["id"]
        if teams
            status 200
            return teams.to_json
        else
            return {}
        end
    end

    teams_get_by_id = lambda do
        protected!
        account = Account.new
        seat = account.get_seat @session_hash["id"], params["id"]
        if seat || @session_hash["admin"]
            org = Organization.new
            team = org.get_team params["id"]
            allowed_seats = org.allowed_seat_types team, @session_hash["admin"]
            team_response = team.as_json
            team_response["user"] = {
                :first_name => team.user.first_name,
                :last_name => team.user.last_name,
                :email => team.user.email,
                :id => team.user.id
            }
            team_response["show"] = ((seat && (seat == "member")) || @session_hash["admin"])
            team_response["seats"] = allowed_seats
            if team.plan
                team_response["plan"] = team.plan
                team_response["default_seat_id"] = team.plan.seat.id
            end
            return team_response.to_json
        else
            redirect to("/unauthorized")
        end
    end

    teams_post = lambda do
        protected!
        status 400
        response = {}
        response[:errors] = []
        begin
            account = Account.new
            if (@session_hash["owner"] || @session_hash["admin"])
                request.body.rewind
                fields = JSON.parse(request.body.read, :symbolize_names => true)
                if fields[:name] && fields[:name].length > 2
                    if fields[:plan_id]
                        org = Organization.new
                        team = org.create_team fields[:name], @session_hash["id"], fields[:plan_id]
                        if team && team["id"]
                            if (org.add_owner @session_hash["id"], team["id"])
                                response = team
                                status 201
                            else
                                response[:errors][0] = {:detail => "An error has occurred"}
                            end
                        else
                            response[:errors][0] = {:detail => "This name is not available"}
                        end
                    else
                        response[:errors][0] = {:detail => "Please select a team type"}
                    end
                else
                    response[:errors][0] = {:detail => "Please enter a more descriptive team name"}
                end
            else
                redirect to("/unauthorized")
            end
        end
        return response.to_json
    end

    sprints_get = lambda do
        issue = Issue.new
        sprints = issue.get_sprints params
        if sprints
            status 200
            return sprints.to_json
        else
            return {}
        end
    end

    sprint_states_get = lambda do
        authorized?
        issue = Issue.new
        if @session_hash
            sprint_states = issue.get_sprint_states params, @session_hash["id"]
        else
            sprint_states = issue.get_sprint_states params, nil
        end
        return sprint_states.to_json
    end

    events_get = lambda do
        issue = Issue.new
        query = {:project_id => params[:project_id].to_i }
        if params[:sprint_id] 
            query[:sprint_id] = params[:sprint_id]
        end
        events = issue.get_events query
        return events.to_json
    end

    events_get_by_sprint = lambda do
        issue = Issue.new
        query = {:project_id => params[:project_id].to_i }
        events = issue.get_events query
        return events.to_json
    end

    sprints_get_by_id = lambda do
        status 404
        issue = Issue.new
        sprint = issue.get_sprints params
        if sprint[0]
            status 200
            return sprint[0].to_json
        else
            return {}
        end
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
                    sprint = issue.create @session_hash["id"], fields[:title],  fields[:description],  fields[:project_id].to_i
                    if sprint
                        state = State.find_by(:name => "idea").id
                        sprint_state = issue.create_sprint_state sprint.id, state, nil
                        log_params = {:sprint_id => sprint.id, :state_id => state, :user_id => @session_hash["id"], :project_id => fields[:project_id], :sprint_state_id => sprint_state["id"]}
                        if sprint_state && (issue.log_event log_params) 
                            status 201
                            response = sprint                            
                        end
                    else
                        response[:error] = "This project does not exist"
                    end
                else
                    response[:error] = "Please enter a more detailed description"                    
                end
            else
                response[:error] = "Please enter a more descriptive title"
            end
        end
        return response.to_json
    end

    sprint_states_post = lambda do
        protected!
        if @session_hash["admin"]
            status 400
            response = {}
            begin
                request.body.rewind
                fields = JSON.parse(request.body.read, :symbolize_names => true)
                if fields[:state]

                    issue = Issue.new
                    sprint = (issue.get_sprint fields[:sprint])

                    repo = Repo.new
                    github = (repo.github_client github_authorization)

                    sha = github.branch("#{sprint.project.org}/#{sprint.project.name}","master").commit.sha

                    sprint_state = issue.create_sprint_state fields[:sprint], fields[:state], sha

                    log_params = {:sprint_id => fields[:sprint], :state_id => fields[:state], :user_id => @session_hash["id"], :project_id => sprint.project.id, :sprint_state_id => sprint_state[:id]} 
                    if sprint_state && (issue.log_event log_params) 
                        status 201
                        response = sprint_state
                    end
                end
            end
            return response.to_json
        else
            redirect to("/unauthorized") 
        end
    end

    contributors_post_comments = lambda do
        protected! 
        status 400
        response = {}
        begin
            request.body.rewind
            fields = JSON.parse(request.body.read, :symbolize_names => true)

            if fields[:text] && fields[:text].length > 1
                issue = Issue.new
                comment = issue.create_comment @session_hash["id"], params[:id], fields[:sprint_state_id], fields[:text]

                sprint_state = issue.get_sprint_state fields[:sprint_state_id]
                query = { :id => sprint_state.sprint_id }
                sprint = issue.get_sprints query
                project_id = sprint[0]["project_id"]

                log_params = {:comment_id => comment.id, :project_id => project_id, :sprint_id => sprint_state.sprint_id, :state_id => sprint_state.state_id, :sprint_state_id =>  sprint_state.id, :user_id => @session_hash["id"], :contributor_id => params[:id]}

                if comment && (issue.log_event log_params)
                    status 201
                    response = comment
                end
            else
                response[:message] = "Please enter a more detailed comment"
            end

        end
        return response.to_json
    end

    contributors_post_votes = lambda do
        protected!
        status 400
        response = {}
        begin
            request.body.rewind
            fields = JSON.parse(request.body.read, :symbolize_names => true)

            issue = Issue.new
            vote = issue.vote @session_hash["id"], params[:id], fields[:sprint_state_id]

            sprint_state = issue.get_sprint_state fields[:sprint_state_id]
            query = { :id => sprint_state.sprint_id }
            sprint = issue.get_sprints query 
            project_id = sprint[0]["project_id"]

            log_params = {:vote_id => vote["id"], :project_id => project_id, :sprint_id => sprint_state.sprint_id, :state_id => sprint_state.state_id, :sprint_state_id =>  sprint_state.id, :user_id => @session_hash["id"], :contributor_id => params[:id]}

            if vote 
                if vote[:created]
                    (issue.log_event log_params)
                end
                status 201
                response = vote
            end

        end
        return response.to_json
    end

    contributors_post_winner = lambda do
        protected!
        status 400
        response = {}
        begin
            if @session_hash["admin"]
                request.body.rewind
                fields = JSON.parse(request.body.read, :symbolize_names => true)

                issue = Issue.new

                query = {:id => fields[:project_id].to_i}
                project = (issue.get_projects query)[0]

                repo = Repo.new
                github = (repo.github_client github_authorization)
                pr = github.create_pull_request("#{project["org"]}/#{project["name"]}", "master", "#{fields[:sprint_state_id].to_i}_#{params[:id].to_i}", "Wired7 #{fields[:sprint_state_id].to_i}_#{params[:id].to_i} to master", body = nil, options = {})

                if pr
                    parameters = {arbiter_id: @session_hash["id"], contributor_id: params[:id], pull_request: pr.number}
                    winner = issue.set_winner fields[:sprint_state_id], parameters
                    if winner

                        sprint_state = issue.get_sprint_state fields[:sprint_state_id]
                        if sprint_state
                            log_params = {:sprint_id => sprint_state.sprint_id, :sprint_state_id =>  sprint_state.id, :user_id => @session_hash["id"], :project_id => project["id"], :contributor_id => params[:id] }
                            if sprint_state && (issue.log_event log_params)
                                status 201
                                response = winner 
                            else

                            end
                        else

                        end
                    else

                    end
                end
            else
                response[:message] = "You are not authorized to do this"
            end
        end
        return response.to_json
    end

    contributors_post_merge = lambda do
        protected!
        status 400
        response = {}
        begin
            if @session_hash["admin"]
                request.body.rewind
                fields = JSON.parse(request.body.read, :symbolize_names => true)

                issue = Issue.new

                query = {:id => fields[:project_id].to_i}
                project = (issue.get_projects query)[0]

                winner = issue.get_winner fields[:sprint_state_id]

                repo = Repo.new
                github = (repo.github_client github_authorization)
                pr = github.merge_pull_request("#{project["org"]}/#{project["name"]}", winner.pull_request, commit_message = "Wired7 #{winner.id}_#{winner.contributor_id} to master", options = {})

                if pr
                    parameters = {merged: true}
                    winner = issue.set_winner fields[:sprint_state_id], parameters
                    status 201
                    response = winner
                else
                    parameters = {merged: false}
                    winner = issue.set_winner fields[:sprint_state_id], parameters
                    status 400
                    response = winner
                end
            else
                response[:message] = "You are not authorized to do this"
            end
        end
        return response.to_json
    end

    refresh_post = lambda do
        protected!
        status 400
        response = {:github_signed => false}
        begin

            issue = Issue.new
            query = {:id => params[:project_id].to_i}
            project = (issue.get_projects query)[0]

            if project
                repo = Repo.new
                github = (repo.github_client github_authorization)
                username = github.login
                if username
                    response[:github_signed] = true

                    repo = Repo.new
                    query = {:project_id => project["id"], :user_id => @session_hash["id"] }
                    contributor = repo.get_contributor query
                    repo.refresh @session, retrieve_github_token, contributor.id, contributor.sprint_state_id, project["org"], project["name"], username, contributor.repo, "master", "master", "master", false
                    status = 200
                    response = contributor
                else
                    response[:message] = "Please sign in to Github"
                end
            else
                response[:message] = "This project is not available"
            end
        rescue => e

        end
        return response.to_json
    end

    contributors_post = lambda do
        protected!
        status 400
        response = {:github_signed => false}
        begin
            request.body.rewind
            fields = JSON.parse(request.body.read, :symbolize_names => true)

            issue = Issue.new

            query = {:id => params[:project_id].to_i}
            project = (issue.get_projects query)[0] 

            if project

                sprint_state = issue.get_sprint_state fields[:sprint_state_id]

                if sprint_state && sprint_state.state && sprint_state.state.contributors

                    repo = Repo.new
                    github = (repo.github_client github_authorization)
                    username = github.login

                    if username

                        response[:github_signed] = true

                        repo = Repo.new
                        query = {:sprint_state_id => sprint_state.id, :user_id => @session_hash["id"] }
                        contributor = repo.get_contributor query

                        if !contributor
                            name = repo.name
                            query = {:id => sprint_state.sprint_id}
                            created = repo.create @session_hash["id"], project["id"], sprint_state.id, name, query
                        else
                            name = contributor.repo
                            created = contributor.id
                        end

                        begin
                            github.create_repository(name)
                        rescue => e
                            puts e
                        end

                        if created
                            status 201
                            response[:id] = created
                            issue = Issue.new
                            sha = (issue.get_sprint_state sprint_state.id).sha
                            repo.refresh @session, retrieve_github_token, created, sprint_state.id, project["org"], project["name"], username, name, "master", sha, sprint_state.id, false
                            repo.refresh @session, retrieve_github_token, created, sprint_state.id, project["org"], project["name"], username, name, "master", sha, "master", false

                            if sprint_state.state.name == "requirements design"
                                idea = issue.get_sprint sprint_state.sprint_id 
                                github.create_contents("#{username}/#{name}",
                                                       "requirements/Requirements-Document-for-Wired7-Sprint-v#{sprint_state.sprint_id}.md",
                                                           "adding placeholder for requirements",
                                                           "##{idea.title}\n\n###Description\n#{idea.description}",
                                                           :branch => sprint_state.id.to_s)
                            end
                        else
                            response[:message] = "Something has gone wrong" 
                        end
                        # background job
                    else
                        response[:message] = "Please sign in to Github" 
                    end
                else
                    response[:message] = "We are not accepting contributions at this time"
                end
            else
                response[:message] = "This project is not available"
            end

        end
        return response.to_json
    end

    contributors_patch_by_id = lambda do
        protected!
        status 400
        response = {}
        begin

            repo = Repo.new
            query = {:id => params[:contributor_id], :user_id => @session_hash["id"] }

            contributor = (repo.get_contributor query)

            if contributor
                contributor.save #update timestamp

                issue = Issue.new

                query = {:id => params[:project_id].to_i}
                project = (issue.get_projects query)[0]

                fetched = repo.refresh nil, nil, contributor[:id], contributor[:sprint_state_id], @session_hash["github_username"], contributor[:repo], project["org"], project["name"], contributor[:sprint_state_id], contributor[:sprint_state_id], "#{contributor[:sprint_state_id]}_#{contributor[:id]}", true

                if fetched
                    contributor.commit = fetched[:sha]
                    contributor.commit_success = fetched[:success]
                    contributor.save
                    status 201
                    response = contributor
                else
                    response[:message] = "An error has occurred"
                end
            else
                response[:message] = "You have not joined yet!"
            end

        rescue => e
            puts e
        end
        return response.to_json
    end

    contributors_get_by_id = lambda do
        protected!
        status 400
        response = {}
        begin
            repo = Repo.new
            query = {:id => params[:contributor_id], :user_id => @session_hash["id"] }
            contributor = repo.get_contributor query
            if contributor
                status 200
                response = contributor
            else
                response[:id] = -1
                response[:message] = "You have not joined yet!"
            end
        rescue => e
            puts e
        end
        return response.to_json
    end

    comments_get = lambda do
        user_id = (default_to_signed params[:user_id])
        if user_id
            issue = Issue.new
            query = {"contributors.user_id" => user_id}
            author = issue.get_comments query

            query = {:user_id => user_id}
            receiver = issue.get_comments query

            return {:author => author, :receiver => receiver, :id => user_id}.to_json
        end
    end

    votes_get = lambda do
        user_id = (default_to_signed params[:user_id])
        if user_id 
            issue = Issue.new 
            query = {"contributors.user_id" => user_id}
            author = issue.get_votes query

            query = {:user_id => user_id}
            receiver = issue.get_votes query

            return {:author => author, :receiver => receiver, :id => user_id}.to_json
        end
    end

    contributors_get = lambda do
        user_id = (default_to_signed params[:user_id])
        if user_id 
            issue = Issue.new 

            query = {:user_id => user_id}

            author = issue.get_contributors query, false #all contributions
            receiver = issue.get_contributors query, true #winning contributions

            return {:author => author, :receiver => receiver, :id => user_id}.to_json
        end
    end

    connections_request_post = lambda do
        protected!
        status 401
        response = {}
        if @session_hash["id"]
            status 400
            begin
                request.body.rewind
                fields = JSON.parse(request.body.read, :symbolize_names => true)

                if fields[:contact_id]
                    issue = Issue.new
                    connection_request = issue.create_connection_request @session_hash["id"], fields[:contact_id]

                    if connection_request
                        status 201
                        response = connection_request
                    end
                else
                    status 400
                end
            end
            return response.to_json
        end
    end

    connections_get = lambda do
        user_id = (default_to_signed params[:user_id])
        if user_id
            issue = Issue.new
            query = {"user_connections.contact_id" => user_id}
            connections = issue.get_user_connections query
            return connections.to_json
        end
    end

    user_connections_get_by_id = lambda do
        protected!
        status 401
        if @session_hash["id"]
            status 400
            begin
                if params[:id]
                    issue = Issue.new
                    response = (issue.user_connections_get_by_id @session_hash["id"], params[:id])
                    if response
                        status 201
                    end
                end
            rescue => e
                puts e
            end
        end
        return response.to_json
    end

    user_connections_patch_read = lambda do
        protected!
        status 401
        response = {}
        if @session_hash["id"]
            status 400
            begin
                request.body.rewind
                fields = JSON.parse(request.body.read, :symbolize_names => true)
                if fields[:user_id] && fields[:read]
                    issue = Issue.new
                    response = (issue.update_user_connections_read @session_hash["id"], fields[:user_id], fields[:read])
                    puts response
                    if response
                        status 201
                    end
                end
            rescue => e
                puts e
            end
        end
        return response.to_json
    end

    user_connections_patch_confirmed = lambda do
        protected!
        status 401
        response = {}
        if @session_hash["id"]
            status 400
            begin
                request.body.rewind
                fields = JSON.parse(request.body.read, :symbolize_names => true)
                if fields[:user_id] && fields[:confirmed]
                    issue = Issue.new
                    response = (issue.update_user_connections_confirmed @session_hash["id"], fields[:user_id], fields[:confirmed])
                    puts response
                    if response
                        status 201
                    end
                end
            rescue => e
                puts e
            end
        end
        return response.to_json
    end

    user_teams_patch = lambda do
        protected!
        status 400
        response = {}
        begin
            request.body.rewind
            fields = JSON.parse(request.body.read, :symbolize_names => true)
            if fields[:token]
                account = Account.new
                team = account.join_team fields[:token], @session_hash["id"]
                if team
                    status 201
                    response = team
                else
                    response[:error] = "This invite is invalid or has expired"
                end
            else
                response[:error] = "Missing token"
            end
        end
        return response.to_json
    end

    user_teams_get = lambda do
        protected!
        account = Account.new
        seat = account.get_seat @session_hash["id"], params["team_id"]
        if (seat && (seat == "member"))|| @session_hash["admin"]
            team = Organization.new
            members = team.get_users params
            return members.to_json 
        else
            redirect to("/unauthorized")
        end
    end

    user_teams_post = lambda do
        protected!
        status 400
        response = {} 
        response[:errors] = []
        begin
            request.body.rewind
            fields = JSON.parse(request.body.read, :symbolize_names => true)
            if fields[:team_id] && fields[:user_email] && fields[:seat_id]
                account = Account.new
                seat = account.get_seat @session_hash["id"], fields[:team_id]
                if (seat && (seat == "member"))|| @session_hash["admin"]
                    team = Organization.new

                    query = {:email => fields[:user_email]}
                    user = account.get query

                    team_info = team.get_team fields[:team_id]

                    allowed_seats = team.allowed_seat_types team_info, @session_hash["admin"]

                    if team.check_allowed_seats allowed_seats, fields[:seat_id]

                        if !user
                            user = account.create fields[:user_email], nil, nil, request.ip
                        end

                        invitation = team.invite_member fields[:team_id], @session_hash["id"], user[:id], user[:email], fields[:seat_id]

                        if invitation
                            status 201
                            account.mail_invite invitation
                            invitation = invitation.as_json
                            invitation.delete("token") #don't return token
                            response = invitation
                        else
                            response[:errors][0] = {:detail => "an error has occurred"}
                        end
                    else
                        response[:errors][0] = {:detail => "seat type not permitted"}
                    end
                else
                    redirect to("/unauthorized")
                end
            end
        end
        return response.to_json
    end

    team_invites_get = lambda do
        status 200
        team = Organization.new
        invite = team.get_member_invite params[:token]
        if invite
            return {
                id: invite.id,
                name: invite.team.name,
                sender_email: invite.sender.email,
                sender_first_name: invite.sender.first_name,
                registered: invite.user.confirmed
            }.to_json
        else
            return {:id => params[:token]}.to_json
        end
    end

    get_user_info = lambda do
        user_id = (default_to_signed params[:user_id])
        if user_id
            issue = Issue.new
            user_info = issue.get_user_info user_id
            return user_info.to_json
        end
    end

    get_user_notifications = lambda do
        user_id = (default_to_signed params[:user_id])
        if user_id
            issue = Issue.new
            user_notification = issue.get_user_notifications user_id
            return user_notification.to_json
        end
    end

    get_user_notifications_by_id = lambda do
        protected!
        status 401
        if @session_hash["id"]
            status 400
            begin
                if params[:id]
                    issue = Issue.new
                    response = (issue.get_user_notifications_by_id @session_hash["id"], params[:id])
                    if response
                        status 201
                    end
                end
            rescue => e
                puts e
            end
        end
        return response.to_json
    end

    user_notifications_read = lambda do
        protected!
        status 401
        response = {}
        if @session_hash["id"]
            status 400
            begin
                request.body.rewind
                fields = JSON.parse(request.body.read, :symbolize_names => true)
                if params[:id] && fields[:read]
                    issue = Issue.new
                    response = (issue.read_user_notifications @session_hash["id"], params[:id], fields[:read])
                    if response
                        status 201
                    end
                end
            rescue => e
                puts e
            end
        end
        return response.to_json
    end

    #API
    post "/register", &register_post
    post "/forgot", &forgot_post
    post "/resend", &resend_invitation_post
    post "/reset", &reset_post
    post "/accept", &accept_post
    post "/login", &login_post
    post "/session/github", &session_provider_github_post
    post "/session/linkedin", &session_provider_linkedin_post
    delete "/session", &session_delete
    get "/session", &session_get

    get "/users/me", &users_get_by_me #must precede :id request
    get "/users/:id", allows: [:id], &users_get_by_id

    get "/users/me/skillsets", &users_skillsets_get_by_me # must precede :user_id request
    get "/users/:user_id/skillsets", &users_skillsets_get
    get "/users/:user_id/skillsets/:skillset_id", &users_skillsets_get_by_skillset
    patch "/users/:user_id/skillsets/:skillset_id", &users_skillsets_patch 

    get "/users/me/roles", &users_roles_get_by_me # must precede :user_id request
    get "/users/:user_id/roles", &users_roles_get
    get "/users/:user_id/roles/:role_id", &users_roles_get_by_role
    patch "/users/:user_id/roles/:role_id", &users_roles_patch_by_id

    post "/account/connections", &connections_request_post
    get "/account/connections/requests", &connections_get
    get "/account/confirmed/connections", &get_user_info
    patch "/account/connections/read/requests/:id", &user_connections_patch_read
    patch "/account/connections/confirme/requests/:id", &user_connections_patch_confirmed
    get "/account/connections/read/requests/:id", &user_connections_get_by_id
    get "/account/connections/confirme/requests/:id", &user_connections_get_by_id
    get "/account/notifications", &get_user_notifications
    patch "/account/read/notifications/:id", &user_notifications_read 
    get "/account/read/notifications/:id", &get_user_notifications_by_id

    get "/roles", &roles_get
    get "/states", &states_get
    get "/skillsets", &skillsets_get
    get "/plans", &plans_get
    get "/seats", &seats_get

    get "/sprints/:sprint_id/skillsets", &sprint_skillsets_get
    get "/sprints/:sprint_id/skillsets/:skillset_id", &sprint_skillsets_get_by_skillset
    patch "/sprints/:sprint_id/skillsets/:skillset_id", &sprint_skillsets_patch 

    get "/repositories", &repositories_get

    post "/projects", &projects_post
    get "/projects", &projects_get
    get "/projects/:id", allows: [:id], &projects_get_by_id

    post "/projects/:project_id/refresh", &refresh_post
    post "/projects/:project_id/contributors", &contributors_post
    patch "/projects/:project_id/contributors/:contributor_id", &contributors_patch_by_id
    get "/projects/:project_id/contributors/:contributor_id", &contributors_get_by_id

    get "/sprints", allows: [:id, :project_id, "sprint_states.state_id"], &sprints_get
    get "/sprints/:id", allows: [:id], &sprints_get_by_id
    post "/sprints", &sprints_post

    get "/sprint-states", allows: [:sprint_id, :id], &sprint_states_get
    post "/sprint-states", &sprint_states_post

    get "/projects/:project_id/events", &events_get

    post "/contributors/:id/comments", &contributors_post_comments
    post "/contributors/:id/votes", &contributors_post_votes
    post "/contributors/:id/winner", &contributors_post_winner
    post "/contributors/:id/merge", &contributors_post_merge

    get "/aggregate-comments", &comments_get
    get "/aggregate-votes", &votes_get
    get "/aggregate-contributors", &contributors_get

    post "/teams", &teams_post
    get "/teams", &teams_get
    get "/teams/:id", allows: [:id], needs: [:id], &teams_get_by_id
    get "/team-invites", &team_invites_get

    post "/user-teams/token", &user_teams_patch
    post "/user-teams", &user_teams_post
    get "/user-teams", allows: [:team_id,:seat_id], needs: [:team_id], &user_teams_get


    get '/unauthorized' do
        status 401
        return {:error => "unauthorized"}.to_json
    end

    error RequiredParamMissing do
        [400, env['sinatra.error'].message]
    end

    # Ember
    get "*" do
        send_file File.expand_path('index.html',settings.public_folder)
    end
end

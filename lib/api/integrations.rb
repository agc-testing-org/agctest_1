require 'sinatra'
require 'mysql2'
require 'sinatra/activerecord'
require 'activerecord-import'
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
require 'rack/throttle'

# Controllers
require_relative '../controllers/account.rb'
require_relative '../controllers/issue.rb'
require_relative '../controllers/repo.rb'
require_relative '../controllers/organization.rb'
require_relative '../controllers/activity.rb'
require_relative '../controllers/feedback.rb'
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
require_relative '../models/user_notification.rb'
require_relative '../models/user_connection.rb'
require_relative '../models/role_state.rb' 

# Workers
require_relative '../workers/user_notification_worker.rb'

# Throttling
require_relative 'rack'

set :database, {
    adapter: "mysql2",  
    username: ENV['INTEGRATIONS_MYSQL_USERNAME'],
    password: ENV['INTEGRATIONS_MYSQL_PASSWORD'],
    host: ENV['INTEGRATIONS_MYSQL_HOST'],
    database: "integrations_#{ENV['RACK_ENV']}"
}  

Sidekiq.configure_server do |config|
    config.redis = { url: "redis://#{ENV['INTEGRATIONS_REDIS_HOST']}:#{ENV['INTEGRATIONS_REDIS_PORT']}/#{ENV['INTEGRATIONS_REDIS_DB']}" }
end

Sidekiq.configure_client do |config|
    config.redis = { url: "redis://#{ENV['INTEGRATIONS_REDIS_HOST']}:#{ENV['INTEGRATIONS_REDIS_PORT']}/#{ENV['INTEGRATIONS_REDIS_DB']}" }
end

class Integrations < Sinatra::Base

    set :public_folder, File.expand_path('integrations-client/dist')

    redis = Redis.new(:host => ENV['INTEGRATIONS_REDIS_HOST'], :port => ENV['INTEGRATIONS_REDIS_PORT'], :db => ENV['INTEGRATIONS_REDIS_DB'])
    message = "you have hit our rate limit"
    key_prefix = :t_

    # Session-Related Routes (less liberal)
    use Rack::Throttle::Hourly, :cache => redis, :key_prefix => key_prefix, :message => message, :max => 15, :rules => { :method => :post, :url => /register/ }
    use Rack::Throttle::Hourly, :cache => redis, :key_prefix => key_prefix, :message => message, :max => 30, :rules => { :method => :post, :url => /(resend|forgot|reset|accept)/ }
    use Rack::Throttle::Hourly, :cache => redis, :key_prefix => key_prefix, :message => message, :max => 30, :rules => { :method => :post, :url => /login/ }
    use Rack::Throttle::Hourly, :cache => redis, :key_prefix => key_prefix, :message => message, :max => 60, :rules => { :method => :post, :url => /session/ }

    # Service-Based Routes
#    use Rack::Throttle::Hourly, :cache => redis, :key_prefix => key_prefix, :message => message, :max => 1600, :rules => { :method => :get, :url => /(users)/ }
    use Rack::Throttle::Hourly, :cache => redis, :key_prefix => key_prefix, :message => message, :max => 70, :rules => { :method => :patch, :url => /(users)/ }
    use Rack::Throttle::Hourly, :cache => redis, :key_prefix => key_prefix, :message => message, :max => 70, :rules => { :method => :post, :url => /(users|contributors)/ }

#    use Rack::Throttle::Hourly, :cache => redis, :key_prefix => key_prefix, :message => message, :max => 500, :rules => { :method => :get, :url => /(sprints|projects|sprint-states|teams|user-teams)/ }
    use Rack::Throttle::Hourly, :cache => redis, :key_prefix => key_prefix, :message => message, :max => 70, :rules => { :method => :patch, :url => /(sprints|projects|sprint-states|teams|user-teams)/ }
    use Rack::Throttle::Hourly, :cache => redis, :key_prefix => key_prefix, :message => message, :max => 70, :rules => { :method => :post, :url => /(sprints|projects|sprint-states|teams|user-teams)/ }

    # Other Routes
#    use Rack::Throttle::Hourly, :cache => redis, :key_prefix => key_prefix, :message => message, :max => 2400, :rules => { :method => :get }
    use Rack::Throttle::Hourly, :cache => redis, :key_prefix => key_prefix, :message => message, :max => 60, :rules => { :method => :delete }

    LinkedIn.configure do |config|
        config.client_id     = ENV["INTEGRATIONS_LINKEDIN_CLIENT_ID"]
        config.client_secret = ENV["INTEGRATIONS_LINKEDIN_CLIENT_SECRET"]
        config.redirect_uri  = "#{ENV['INTEGRATIONS_HOST']}/callback/linkedin"
    end

    register Sinatra::StrongParams

    def protected!
        @session = retrieve_token
        return if authorized?
        return_unauthorized 
    end

    def authorized?
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
        if @session_hash["github_token"]
            account = Account.new
            return account.unlock_github_token @session, @session_hash["github_token"] 
        end 
    end

    def retrieve_token
        if request.env["HTTP_AUTHORIZATION"]
            return request.env["HTTP_AUTHORIZATION"].split("Bearer ")[1]
        else
            return nil
        end
    end

    def session_tokens user, owner, initial 

        account = Account.new
        user_secret = SecureRandom.hex(32) #session secret, not password
        user_refresh = SecureRandom.hex(32)
        expiration = 60 * 15 # 15 min
        jwt = account.create_token user[:id], user_secret, user[:name]

        github_access_token = nil
        github_token = nil

        if @session_hash && @session_hash["github_token"]
            github_access_token = github_authorization
            github_token = account.create_token user[:id], user_secret, github_access_token
        end

        update_fields = {
            ip: request.ip,
            jwt: jwt,
            refresh: user_refresh
        }

        github_username = user[:github_username]
        if @session_hash && @session_hash["github_username"]
            github_username = @session_hash["github_username"]
            update_fields[:github_username] = @session_hash["github_username"]
        end

        session_hash = {:key => user_secret, :id => user[:id], :first_name => user[:first_name], :last_name => user[:last_name], :admin => user[:admin], :owner => owner, :github_username => github_username, :github_token => github_token}.to_json

        if user[:jwt] && (account.get_key "session", user[:jwt]) # session refresh does not require Bearer
            account.save_token "session", user[:jwt], session_hash, 30 #expire old token in 30s 
        end

        if (account.save_token "session", jwt, session_hash, expiration) && (account.update user[:id], update_fields)
            response = {
                :success => true,
                :access_token => jwt,
                :expires_at => (Time.now + expiration).to_i,
                :expires_in => expiration,
                :refresh_token => user_refresh
            }
            initial && (account.record_login user[:id], request.ip)
            status 200
            return response
        end
    end

    def return_not_found
        response = {:errors => [{
            :detail => "not found"
        }]}
        halt 404, response.to_json
    end

    def return_unauthorized
        response = {:errors => [{
            :detail => "unauthorized"
        }]}                     
        halt 401, response.to_json
    end

    def return_unauthorized_admin
        return_error "this action requires additional authorization"
    end

    def return_error message
        response = {:errors => [{
            :detail => message        
        }]}
        halt 400, response.to_json
    end

    def check_required_field field, name
        if field 
            return true
        else
            return_error "missing #{name} field"
        end
    end

    def get_json
        begin
            request.body.rewind
            return JSON.parse(request.body.read, :symbolize_names => true)
        rescue => e
            puts e
            return_error "invalid request"
        end
    end

    # API
    forgot_post = lambda do
        fields = get_json
        account = Account.new
        (account.valid_email fields[:email]) || (return_error "please enter a valid email address")
        (account.request_token fields[:email]) || (return_error "we couldn't find this email address")
        status 201
        return {:success => true}.to_json
    end

    resend_invitation_post = lambda do
        fields = get_json
        account = Account.new
        check_required_field fields[:token], "token"
        invite = account.refresh_team_invite fields[:token]
        invite || (return_error "we couldn't find this invitation")
        account.mail_invite invite
        status 201
        return {:success => true}.to_json
    end

    register_post = lambda do
        fields = get_json
        check_required_field fields[:first_name], "first name"
        account = Account.new
        first_name_length = fields[:first_name].to_s.length
        (first_name_length < 31 && account.safe_string(fields[:first_name],2)) || (return_error "your first name must be 2-30 characters (only letters, numbers, dashes)")
        (account.valid_email fields[:email]) || (return_error "please enter a valid email address.")
        user = account.create fields[:email], fields[:first_name], fields[:last_name], request.ip
        (user && user.id) || (return_error "this email is already registered (or has been invited)")
        account.create_email user
        if fields[:roles].length < 5 #accept roles from people that sign up without an invite
            fields[:roles].each do |r|
                account.update_role user.id, r[:id], r[:active]
            end
        end
        status 201
        return {:success => true}.to_json
    end

    accept_post = lambda do
        fields = get_json
        check_required_field fields[:token], "token"
        check_required_field fields[:password], "password"
        check_required_field fields[:firstName], "first name"
        account = Account.new
        first_name_length = fields[:firstName].to_s.length
        (first_name_length < 31 && account.safe_string(fields[:firstName],2)) || (return_error "your first name must be 2-30 characters (only letters, numbers, dashes)")
        password_length = fields[:password].to_s.length
        (password_length > 7 && password_length < 31) || (return_error "your password must be 8-30 characters")
        invitation = account.get_invitation fields[:token]
        (invitation.first && invitation.first.user_id) || (return_error "this invitation is invalid")
        team = account.join_team invitation
        team || (return_error "this invitation has expired")
        user_params = {:id => team["user_id"]}
        user = account.get user_params
        (account.confirm_user user, fields[:password], fields[:firstName], request.ip) || (return_error "unable to accept this invitation at this time")
        owner = ((account.is_owner? user[:id]) || user[:admin])
        status 200
        return (session_tokens user, owner, true).to_json
    end

    reset_post = lambda do
        fields = get_json
        check_required_field fields[:token], "token"
        check_required_field fields[:password], "password"
        account = Account.new
        password_length = fields[:password].to_s.length
        (password_length > 7 && password_length < 31) || (return_error "your password must be 8-30 characters")
        user = account.get_reset_token fields[:token]
        user || (return_error "this token has expired")
        (account.confirm_user user, fields[:password], user.first_name, request.ip) || (return_error "unable to reset your password at this time")
        owner = ((account.is_owner? user[:id]) || user[:admin])
        status 200
        return (session_tokens user, owner, true).to_json
    end

    login_post = lambda do
        fields = get_json
        check_required_field fields[:email], "password"
        check_required_field fields[:password], "password"
        account = Account.new
        user = account.sign_in fields[:email], fields[:password], request.ip
        user || (return_error "email or password incorrect")
        owner = ((account.is_owner? user[:id]) || user[:admin]) 
        status 200
        return (session_tokens user, owner, true).to_json
    end

    session_provider_linkedin_post = lambda do
        protected!
        fields = get_json
        account = Account.new
        filters = {:id => @session_hash["id"]}
        user = account.get filters
        user || return_unauthorized 
        access_token = account.linkedin_code_for_token(fields[:auth_code])
        #ALWAYS RETURN session tokens, even if conditions below fail
        #access_token || (return_error "invalid code")
        linkedin = (account.linkedin_client access_token)
        #linkedin || (return_error "invalid access token")
        pulled = account.pull_linkedin_profile linkedin
        #pulled || (return_error "could not pull profile")
        profile_id = account.post_linkedin_profile @session_hash["id"], pulled
        (profile_id && (account.post_linkedin_profile_positions profile_id, pulled.positions.all[0])) #|| (return_error "could not save profile")
        response = (session_tokens user, @session_hash["owner"], false) 
        response[:success] = !profile_id.nil?
        status 200
        return response.to_json
    end

    session_provider_github_post = lambda do
        protected!
        fields = get_json
        account = Account.new
        filters = {:id => @session_hash["id"]}
        user = account.get filters
        user || return_unauthorized
        access_token = account.github_code_for_token(fields[:auth_code])
        #access_token || (return_error "invalid code")        
        repo = Repo.new
        github = (repo.github_client access_token)
        #github || (return_error "invalid access token")
        @session_hash["github_username"] = github.login || nil
        provider_token = account.create_token @session_hash["id"], @key, access_token 
        @session_hash["github_token"] = provider_token
        response = (session_tokens user, @session_hash["owner"], false)
        response[:success] = !@session_hash["github_username"].nil?
        status 200
        return response.to_json
    end

    session_post = lambda do
        check_required_field params[:grant_type], "grant_type"
        (params[:grant_type] == "refresh_token") || (return_error "invalid grant_type")        
        account = Account.new
        filters = {:refresh => params[:refresh_token]}
        user = account.get filters
        user || return_unauthorized 
        owner = ((account.is_owner? user[:id]) || user[:admin])
        status 200
        return (session_tokens user, owner, false).to_json
    end

    session_delete = lambda do
        protected!
        account = Account.new
        filters = {:jwt => @session}
        user = account.get filters
        (account.delete_token "session", @session) && (user.update({:refresh => nil})) || (return_error "sign out failed")
        status 200
        return {:success => true}.to_json
    end

    session_get = lambda do
        protected!
        status 200
        return {:id => @session_hash["id"], :first_name => @session_hash["first_name"], :last_name => @session_hash["last_name"], :admin => @session_hash["admin"], :owner => @session_hash["owner"], :github => !@session_hash["github_token"].nil?, :github_username => @session_hash["github_username"]}.to_json
    end

    users_get_by_id = lambda do
        account = Account.new
        user = account.get_users params
        user[0] || return_not_found
        status 200
        return user[0].to_json
    end

    users_get_by_me = lambda do
        protected!
        redirect to("/users/#{@session_hash["id"]}")
    end

    users_roles_get = lambda do
        account = Account.new
        status 200
        return (account.get_account_roles params[:user_id], nil).to_json
    end

    users_roles_get_by_me = lambda do
        protected!
        redirect to("/users/#{@session_hash["id"]}/roles")
    end

    users_roles_get_by_role = lambda do
        protected!
        check_required_field params[:role_id], "role_id"
        account = Account.new
        query = {:id => params[:role_id]}
        status 200
        return (account.get_account_roles @session_hash["id"], query)[0].to_json
    end

    users_roles_patch_by_id = lambda do
        protected!
        check_required_field params[:role_id], "role_id"
        fields = get_json
        check_required_field !fields[:active].nil?, "active"
        account = Account.new
        response = (account.update_user_role @session_hash["id"], params[:role_id], fields[:active])
        response || (return_error "unable not update role")
        status 200
        return response.to_json
    end

    roles_get = lambda do
        account = Account.new
        status 200
        return account.get_roles.to_json
    end

    states_get = lambda do
        issue = Issue.new
        status 200
        return (issue.get_states nil).to_json
    end

    skillsets_get = lambda do
        issue = Issue.new
        status 200
        return (issue.get_skillsets).to_json
    end

    plans_get = lambda do
        status 200
        return (Plan.all.as_json).to_json
    end

    seats_get = lambda do
        status 200
        return (Seat.all.as_json).to_json
    end

    sprint_skillsets_get = lambda do
        check_required_field params[:sprint_id], "sprint_id"
        issue = Issue.new
        status 200
        return (issue.get_sprint_skillsets params[:sprint_id], nil).to_json
    end

    sprint_skillsets_get_by_skillset = lambda do
        check_required_field params[:sprint_id], "sprint_id"
        check_required_field params[:skillset_id], "skillset_id"
        issue = Issue.new
        query = {:id => params[:skillset_id]}
        status 200
        return (issue.get_sprint_skillsets params[:sprint_id], query)[0].to_json
    end

    sprint_skillsets_patch = lambda do
        protected! 
        @session_hash["admin"] || return_unauthorized_admin
        check_required_field params[:sprint_id], "sprint_id"
        check_required_field params[:skillset_id], "skillset_id"
        fields = get_json
        check_required_field !fields[:active].nil?, "active"
        issue = Issue.new
        response = (issue.update_skillsets params[:sprint_id], params[:skillset_id], fields[:active])
        response || (return_error "unable to update skillset")
        status 200
        return response.to_json
    end

    users_skillsets_get = lambda do
        check_required_field params[:user_id], "user_id"
        issue = Issue.new
        status 200
        return (issue.get_user_skillsets params[:user_id], nil).to_json
    end

    users_skillsets_get_by_me = lambda do
        protected!
        redirect to("/users/#{@session_hash["id"]}/skillsets")
    end

    users_skillsets_get_by_skillset = lambda do
        protected!
        check_required_field params[:skillset_id], "skillset_id"
        issue = Issue.new
        query = {:id => params[:skillset_id]}
        status 200
        return (issue.get_user_skillsets @session_hash["id"], query)[0].to_json
    end

    users_skillsets_patch = lambda do
        protected!
        check_required_field params[:skillset_id], "skillset_id"
        fields = get_json
        check_required_field !fields[:active].nil?, "active"  
        issue = Issue.new
        response = (issue.update_user_skillsets @session_hash["id"], params[:skillset_id], fields[:active])
        response || (return_error "unable to update skillset")
        status 200
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
        status 200
        return repositories.to_json
    end

    projects_get = lambda do
        issue = Issue.new
        projects = issue.get_projects nil
        status 200
        return projects.to_json
    end

    projects_get_by_id = lambda do
        issue = Issue.new
        project = issue.get_projects params
        (project && project[0]) || return_not_found
        status 200
        return project[0].to_json
    end

    projects_post = lambda do
        protected!
        @session_hash["admin"] || return_unauthorized_admin
        fields = get_json
        check_required_field fields[:org], "org"
        check_required_field fields[:org], "name"
        issue = Issue.new
        project = issue.create_project @session_hash["id"], fields[:org], fields[:name]
        project || (return_error "unable to create project")
        status 201
        return project.to_json
    end

    teams_get = lambda do
        protected!
        account = Account.new
        status 200
        return (account.get_teams @session_hash["id"]).to_json
    end

    teams_get_by_id = lambda do
        protected!
        check_required_field params["id"], "id"
        account = Account.new
        seat = account.get_seat @session_hash["id"], params["id"]
        (seat || @session_hash["admin"]) || return_not_found
        org = Organization.new
        team = org.get_team params["id"]
        team || (return_error "unable to retrieve team")
        allowed_seats = org.allowed_seat_types team, @session_hash["admin"]
        allowed_seats || (return_error "unable to retrieve team")
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
        status 200
        return team_response.to_json
    end

    teams_post = lambda do
        protected!
        (@session_hash["owner"] || @session_hash["admin"]) || return_unauthorized_admin
        fields = get_json
        check_required_field fields[:name], "name"
        check_required_field fields[:plan_id], "plan_id"
        name_length = fields[:name].to_s.length
        account = Account.new
        (name_length < 31 && name_length > 1) || (return_error "team name must be 2-30 characters") 
        (Plan.find_by(:id => fields[:plan_id])) || (return_error "invalid plan_id")
        org = Organization.new
        team = org.create_team fields[:name], @session_hash["id"], fields[:plan_id]
        (team && team["id"]) || (return_error "this name is not available")
        (org.add_owner @session_hash["id"], team["id"]) || (return_error "unable to create team")
        status 201
        return team.to_json
    end

    sprints_get = lambda do
        issue = Issue.new
        sprints = issue.get_sprints params
        status 200
        return sprints.to_json
    end

    sprint_states_get = lambda do
        @session = retrieve_token
        authorized?
        issue = Issue.new
        sprint_states = issue.get_sprint_states params, ((@session_hash["id"] if @session_hash) || nil)
        status 200
        return sprint_states.to_json
    end

    sprints_get_by_id = lambda do
        issue = Issue.new
        sprint = issue.get_sprints params
        (sprint && sprint[0]) || return_not_found
        status 200
        return sprint[0].to_json
    end

    sprints_post = lambda do
        protected!
        fields = get_json
        check_required_field fields[:title], "title"
        check_required_field fields[:description], "description"
        check_required_field fields[:project_id], "project_id"

        account = Account.new
        title_length = fields[:title].to_s.length
        (title_length < 101 && title_length > 4) || (return_error "title must be 5-100 characters")

        description_length = fields[:description].to_s.length
        (description_length < 501 && description_length > 4) || (return_error "description must be 5-500 characters")
        
        issue = Issue.new
        sprint = issue.create @session_hash["id"], fields[:title],  fields[:description],  fields[:project_id].to_i
        sprint || (return_error "unable to create sprint for this project")

        state = State.find_by(:name => "idea").id
        sprint_state = issue.create_sprint_state sprint.id, state, nil
        sprint_state || (return_error "unable to create sprint")
        log_params = {:sprint_id => sprint.id, :state_id => state, :user_id => @session_hash["id"], :project_id => fields[:project_id], :sprint_state_id => sprint_state.id, :diff => "new"}
        (issue.log_event log_params) || (return_error "unable to create sprint")
        status 201
        return sprint.to_json
    end

    sprint_states_post = lambda do
        protected!
        @session_hash["admin"] || return_unauthorized_admin
        fields = get_json
        check_required_field fields[:state], "state"
        check_required_field fields[:sprint], "sprint"

        issue = Issue.new
        sprint = (issue.get_sprint fields[:sprint])
        sprint || return_not_found
        repo = Repo.new
        github = (repo.github_client github_authorization)
        sprint || (return_error "unable to connect to github")
        sha = github.branch("#{sprint.project.org}/#{sprint.project.name}","master").commit.sha
        sha || (return_error "unable to retrieve sha")
        sprint_state = issue.create_sprint_state fields[:sprint], fields[:state], sha
        sprint_state || (return_error "unable to create sprint state")
        log_params = {:sprint_id => fields[:sprint], :state_id => fields[:state], :user_id => @session_hash["id"], :project_id => sprint.project.id, :sprint_state_id => sprint_state.id, :diff => "transition"} 
        (issue.log_event log_params) ||  (return_error "unable to create sprint state")
        status 201
        return sprint_state.to_json
    end

    contributors_post_comments = lambda do
        protected! 
        fields = get_json
        check_required_field fields[:text], "text"
        check_required_field fields[:sprint_state_id], "sprint_state_id"
        comment_length = fields[:text].to_s.length
        (comment_length > 1 && comment_length < 5001) || (return_error "comments must be 2-5000 characters") 
        issue = Issue.new
        comment = issue.create_comment @session_hash["id"], params[:id], fields[:sprint_state_id], fields[:text]
        comment || (return_error "unable to save comment")
        sprint_state = issue.get_sprint_state fields[:sprint_state_id]
        sprint_ids = issue.get_sprint_state_ids_by_sprint sprint_state.sprint_id
        next_sprint_state_id = issue.get_next_sprint_state sprint_state.id, sprint_ids
        log_params = {:comment_id => comment.id, :project_id => sprint_state.sprint.project.id, :sprint_id => sprint_state.sprint_id, :state_id => sprint_state.state_id, :sprint_state_id =>  sprint_state.id, :next_sprint_state_id => next_sprint_state_id, :user_id => @session_hash["id"], :contributor_id => params[:id], :diff => "comment"}        
        (issue.log_event log_params) || (return_error "an error has occurred")
        status 201
        return comment.to_json
    end

    contributors_post_votes = lambda do
        protected!
        fields = get_json
        check_required_field fields[:sprint_state_id], "sprint_state_id"
        issue = Issue.new
        vote = issue.vote @session_hash["id"], params[:id], fields[:sprint_state_id]
        vote || (return_error "unable to save vote")
        vote[:created] || (halt 200, vote.to_json) # vote already cast, don't save another event
        sprint_state = issue.get_sprint_state fields[:sprint_state_id]
        sprint_ids = issue.get_sprint_state_ids_by_sprint sprint_state.sprint_id
        next_sprint_state_id = issue.get_next_sprint_state sprint_state.id, sprint_ids
        log_params = {:vote_id => vote["id"], :project_id => sprint_state.sprint.project.id, :sprint_id => sprint_state.sprint_id, :state_id => sprint_state.state_id, :sprint_state_id =>  sprint_state.id, :next_sprint_state_id => next_sprint_state_id, :user_id => @session_hash["id"], :contributor_id => params[:id], :diff => "vote"}
        (issue.log_event log_params) || (return_error "an error has occurred")
        status 201
        return vote.to_json
    end

    contributors_post_winner = lambda do
        protected!
        @session_hash["admin"] || return_unauthorized_admin
        fields = get_json
        check_required_field fields[:sprint_state_id], "sprint_state_id"
        issue = Issue.new
        sprint_state = issue.get_sprint_state fields[:sprint_state_id]
        sprint_state || return_not_found
        repo = Repo.new
        github = (repo.github_client github_authorization)
        github || (return_error "unable to authenticate github")
        (pr = github.create_pull_request("#{sprint_state.sprint.project.org}/#{sprint_state.sprint.project.name}", "master", "#{fields[:sprint_state_id].to_i}_#{params[:id].to_i}", "Wired7 #{fields[:sprint_state_id].to_i}_#{params[:id].to_i} to master", body = nil, options = {})) rescue (return_error "unable to create pull request") # could exist already
        parameters = {arbiter_id: @session_hash["id"], contributor_id: params[:id], pull_request: pr.number}
        sprint_state.update_attributes!(parameters) rescue (return_error "unable to set winner") 
        sprint_ids = issue.get_sprint_state_ids_by_sprint sprint_state.sprint_id
        next_sprint_state_id = issue.get_next_sprint_state sprint_state.id, sprint_ids
        log_params = {:sprint_id => sprint_state.sprint_id, :sprint_state_id => sprint_state.id, :next_sprint_state_id => next_sprint_state_id, :user_id => @session_hash["id"], :project_id => sprint_state.sprint.project.id, :contributor_id => params[:id], :diff => "winner" }
        (sprint_state && (issue.log_event log_params)) || (return_error "an error has occurred")
        status 201
        return sprint_state.to_json 
    end

    contributors_post_merge = lambda do
        protected!
        @session_hash["admin"] || return_unauthorized_admin
        fields = get_json
        check_required_field fields[:sprint_state_id], "sprint_state_id"
        issue = Issue.new
        winner = issue.get_sprint_state fields[:sprint_state_id]
        winner || return_not_found
        winner.contributor_id || (return_error "a contribution has not been selected")
        repo = Repo.new
        github = (repo.github_client github_authorization)
        github || (return_error "unable to authenticate github")
        pr = github.merge_pull_request("#{winner.sprint.project.org}/#{winner.sprint.project.name}", winner.pull_request, commit_message = "Wired7 #{winner.id}_#{winner.contributor_id} to master", options = {})
        pr || (return_error "unable to find pull request")
        winner.merged = true
        winner.save
        status 201
        return winner.to_json 
    end

    refresh_post = lambda do #TODO we can use this later to refresh a github project we forked with a project from another owner (will allow us to include non-wired7 org projects)
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
                    repo.refresh @session, @session_hash["github_token"], contributor.id, contributor.sprint_state_id, project["org"], project["name"], username, contributor.repo, "master", "master", "master", false
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
        fields = get_json
        check_required_field fields[:sprint_state_id], "sprint_state_id"
        issue = Issue.new
        sprint_state = issue.get_sprint_state fields[:sprint_state_id]
        (sprint_state && sprint_state.state) || return_not_found
        sprint_state.state.contributors || (return_error "unable to join this phase")

        repo = Repo.new
        github = (repo.github_client github_authorization)
        github || (return_error "unable to authenticate github")
        username = github.login
        username || (return_error "unable to fetch github username")

        query = {"sprint_states.sprint_id" => sprint_state.sprint_id, :user_id => @session_hash["id"] } #check for sprint, not sprint state
        contributor = repo.get_contributor query
        (contributor && (name = contributor.repo)) || (name = repo.name)

        created = repo.create @session_hash["id"], sprint_state.id, name
        created || (return_error "unable to join")
        if !contributor
            begin
                github.create_repository(name)
            rescue => e
                puts e
            end
        end

        sha = (issue.get_sprint_state sprint_state.id).sha
        (repo.refresh @session, @session_hash["github_token"], created, sprint_state.id, sprint_state.sprint.project.org, sprint_state.sprint.project.name, username, name, "master", sha, sprint_state.id, false) || (return_error "unable to update sprint phase branch")
        (repo.refresh @session, @session_hash["github_token"], created, sprint_state.id, sprint_state.sprint.project.org, sprint_state.sprint.project.name, username, name, "master", sha, "master", false) || (return_error "unable to update master branch")

        (sprint_state.state.name == "requirements design" && !contributor) || (halt 201, {:id => created}.to_json) # only need to create doc if first time contributing
        (github.create_contents("#{username}/#{name}",
                                "requirements/Requirements-Document-for-Wired7-Sprint-v#{sprint_state.sprint_id}.md",
                                    "adding placeholder for requirements",
                                    "# #{sprint_state.sprint.title}\n\n### Description\n#{sprint_state.sprint.description}", #space required between markdown header and first letter
                                    :branch => sprint_state.id.to_s)) || (return_error "unable to create requirements document")
        status 201
        return {:id => created}.to_json
    end

    contributors_patch_by_id = lambda do
        protected!
        repo = Repo.new
        check_required_field params[:contributor_id], "contributor_id"
        query = {:id => params[:contributor_id], :user_id => @session_hash["id"] }
        contributor = repo.get_contributor query
        contributor || return_not_found
        contributor.save #update timestamp
        issue = Issue.new
        query = {:id => params[:project_id].to_i}
        project = (issue.get_projects query)[0]
        project || (return_error "unable to update contribution")
        fetched = repo.refresh nil, nil, contributor[:id], contributor[:sprint_state_id], @session_hash["github_username"], contributor[:repo], project["org"], project["name"], contributor[:sprint_state_id], contributor[:sprint_state_id], "#{contributor[:sprint_state_id]}_#{contributor[:id]}", true
        fetched || (return_error "unable to update contribution")
        contributor.commit = fetched[:sha]
        contributor.commit_success = fetched[:success]
        contributor.save
        status 200
        return contributor.to_json 
    end

    contributors_get_by_id = lambda do
        protected!
        repo = Repo.new
        check_required_field params[:contributor_id], "contributor_id"
        query = {:id => params[:contributor_id], :user_id => @session_hash["id"] }
        contributor = repo.get_contributor query
        contributor || return_not_found
        status 200
        return contributor.to_json
    end

    connections_request_post = lambda do
        protected!
        check_required_field params[:id], "id"
        account = Account.new
        status 201
        return (account.create_connection_request @session_hash["id"], params[:id]).to_json
    end

    connections_requests_get = lambda do
        protected!
        account = Account.new 
        query = {"user_connections.contact_id" => @session_hash["id"]}
        status 200
        return (account.get_user_connections query).to_json
    end

    get_exist_request = lambda do
        protected!
        check_required_field params[:id], "id"
        account = Account.new
        query = {"user_connections.contact_id" =>  params[:id], :user_id => @session_hash["id"]} 
        outgoing = account.get_user_connections query
        query = {"user_connections.user_id" =>  params[:id], "user_connections.contact_id" => @session_hash["id"]}
        incoming = account.get_user_connections query
        all = (outgoing + incoming)
        (all && all[0]) || (halt 200, {:id => 0}.to_json) 
        status 200
        return all[0].to_json
    end

    connections_get = lambda do
        protected!
        account = Account.new
        accepted = account.get_user_connections_accepted @session_hash["id"]
        requested = account.get_user_connections_requested @session_hash["id"]
        status 200
        return (accepted + requested).to_json
    end

    connections_requests_get_by_id = lambda do
        protected!
        check_required_field params[:id], "id"
        account = Account.new
        query = {:id =>  params[:id], :contact_id => @session_hash["id"]} 
        requests = account.get_user_connections query
        requests || (return_error "request not found")
        status 200
        return requests[0].to_json
    end

    user_connections_patch = lambda do
        protected!
        fields = get_json
        check_required_field fields[:user_id], "user_id"
        check_required_field fields[:read], "read"
        check_required_field fields[:confirmed], "confirmed"
        account = Account.new
        status 200
        return (account.update_user_connections @session_hash["id"], fields[:user_id], fields[:read], fields[:confirmed]).to_json
    end

    user_teams_patch = lambda do
        protected!
        fields = get_json
        check_required_field fields[:token], "token"
        account = Account.new
        invitation = account.get_invitation fields[:token]
        (invitation.first && invitation.first.user_id) || (return_error "this invitation is invalid")
        (@session_hash["id"] == invitation.first.user_id) || (return_error "this invitation is invalid")
        team = account.join_team invitation
        team || (return_error "this invitation has expired")
        status 200
        return team.to_json 
    end

    user_teams_get = lambda do
        protected!
        check_required_field params["team_id"], "team_id"
        account = Account.new
        seat = account.get_seat @session_hash["id"], params["team_id"]
        ((seat && (seat == "member")) || @session_hash["admin"]) || return_not_found
        team = Organization.new
        status 200
        return (team.get_users params).to_json
    end

    user_teams_post = lambda do
        protected!
        fields = get_json
        check_required_field fields[:team_id], "team_id"
        check_required_field fields[:seat_id], "seat_id"

        account = Account.new
        (account.valid_email fields[:user_email]) || (return_error "please enter a valid email address")

        seat = account.get_seat @session_hash["id"], fields[:team_id]
        ((seat && (seat == "member")) || @session_hash["admin"]) || return_not_found
        team = Organization.new

        team_info = team.get_team fields[:team_id]
        allowed_seats = team.allowed_seat_types team_info, @session_hash["admin"]
        (team.check_allowed_seats allowed_seats, fields[:seat_id]) || (return_error "invalid seat_id")

        query = {:email => fields[:user_email]}
        user = account.get query
        user = (user || (account.create fields[:user_email], nil, nil, request.ip))
        invitation = team.invite_member fields[:team_id], @session_hash["id"], user[:id], user[:email], fields[:seat_id]
        (invitation && (account.mail_invite invitation)) || (return_error "invite error")
        invitation = invitation.as_json
        invitation.delete("token")
        status 201
        return invitation.to_json
    end

    team_invites_get = lambda do
        check_required_field params[:token], "token"
        team = Organization.new
        invite = team.get_member_invite params[:token]
        (invite && invite.first) || (halt 200, {:id => 0, :valid => false}.to_json)
        (team.invite_expired? invite) || (halt 200, {:id => invite.first.id, expired: true, valid: true}.to_json)
        status 200
        return {
            id: invite.first.id,
            registered: invite.first.user.confirmed,
            valid: true,
            expired: false,
            name: invite.first.team.name
        }.to_json
    end

    get_user_notifications = lambda do
        protected!
        account = Account.new
        status 200
        return (account.get_user_notifications @session_hash["id"]).to_json
    end

    get_user_notifications_by_id = lambda do
        protected!
        check_required_field params[:id], "id"
        account = Account.new
        response = (account.get_user_notifications_by_id @session_hash["id"], params[:id])
        response || return_not_found
        status 200
        return response.to_json
    end

    user_notifications_read = lambda do
        protected!
        check_required_field params[:id], "id"
        fields = get_json
        check_required_field fields[:read], "read"
        account = Account.new
        notification = account.get_user_notifications_by_id @session_hash["id"], params[:id]
        response || return_not_found
        notification.read = fields[:read] 
        notification.save
        status 200
        return notification.to_json
    end

    get_user_comments_created_by_skillset_and_roles = lambda do
        feedback = Feedback.new
        requests = feedback.user_comments_created_by_skillset_and_roles params
        requests || (return_error "unable to retrieve comments") 
        return (feedback.build_feedback requests).to_json
    end

    get_user_comments_received_by_skillset_and_roles = lambda do
        feedback = Feedback.new
        requests = feedback.user_comments_received_by_skillset_and_roles params
        requests || (return_error "unable to retrieve comments") 
        return (feedback.build_feedback requests).to_json
    end

    get_user_votes_cast_by_skillset_and_roles = lambda do
        feedback = Feedback.new
        requests = feedback.user_votes_cast_by_skillset_and_roles params
        requests || (return_error "unable to retrieve votes")
        return (feedback.build_feedback requests).to_json
    end

    get_user_votes_received_by_skillset_and_roles = lambda do
        feedback = Feedback.new
        requests = feedback.user_votes_received_by_skillset_and_roles params
        requests || (return_error "unable to retrieve votes")
        return (feedback.build_feedback requests).to_json
    end

    get_user_contributions_created_by_skillset_and_roles = lambda do
        feedback = Feedback.new
        requests = feedback.user_contributions_created_by_skillset_and_roles params
        requests || (return_error "unable to retrieve contribution")
        return (feedback.build_contribution_feedback requests).to_json
    end

    get_user_contributions_selected_by_skillset_and_roles = lambda do
        feedback = Feedback.new
        requests = feedback.user_contributions_selected_by_skillset_and_roles params
        requests || (return_error "unable to retrieve winner")
        return (feedback.build_feedback requests).to_json
    end

    get_user_comments_created_by_skillset_and_roles_by_me = lambda do
        protected!
        url = "/users/#{@session_hash["id"]}/aggregate-comments?#{params.to_param}"
        redirect to url
    end

    get_user_votes_cast_by_skillset_and_roles_by_me = lambda do
        protected!
        url = "/users/#{@session_hash["id"]}/aggregate-votes?#{params.to_param}"
        redirect to url
    end

    get_user_contributions_created_by_skillset_and_roles_by_me = lambda do
        protected!
        url = "/users/#{@session_hash["id"]}/aggregate-contributors?#{params.to_param}"
        redirect to url
    end

    get_user_comments_received_by_skillset_and_roles_by_me = lambda do
        protected!
        url = "/users/#{@session_hash["id"]}/aggregate-comments-received?#{params.to_param}"
        redirect to url
    end

    get_user_votes_received_by_skillset_and_roles_by_me = lambda do
        protected!
        url = "/users/#{@session_hash["id"]}/aggregate-votes-received?#{params.to_param}"
        redirect to url
    end

    get_user_contributions_selected_by_skillset_and_roles_by_me = lambda do
        protected!
        url = "/users/#{@session_hash["id"]}/aggregate-contributors-received?#{params.to_param}"
        redirect to url
    end

    team_connections_get = lambda do
        protected!
        account = Account.new

        team_id = params[:id]
        seat = account.get_seat @session_hash["id"], params[:id]

        if seat == "member"
            accepted = account.get_team_connections_accepted team_id
            requested = account.get_team_connections_requested team_id
            status 200
        else
            return_not_found
        end
        return (accepted + requested).to_json
    end

    #API

    post "/register", &register_post
    post "/forgot", &forgot_post
    post "/resend", &resend_invitation_post
    post "/reset", &reset_post
    post "/accept", &accept_post
    post "/login", &login_post
    post "/session", &session_post #refresh_token
    post "/session/github", &session_provider_github_post
    post "/session/linkedin", &session_provider_linkedin_post
    delete "/session", &session_delete
    get "/session", &session_get

    get "/users/me/skillsets", &users_skillsets_get_by_me # must precede :user_id request
    get "/users/:user_id/skillsets", &users_skillsets_get
    get "/users/me/skillsets/:skillset_id", &users_skillsets_get_by_skillset
    patch "/users/me/skillsets/:skillset_id", &users_skillsets_patch 

    get "/users/me/roles", &users_roles_get_by_me # must precede :user_id request
    get "/users/:user_id/roles", &users_roles_get
    get "/users/me/roles/:role_id", &users_roles_get_by_role
    patch "/users/me/roles/:role_id", &users_roles_patch_by_id

    get "/users/me/notifications", &get_user_notifications
    patch "/users/me/notifications/:id", &user_notifications_read
    get "/users/me/notifications/:id", &get_user_notifications_by_id

    get "/users/me/connections", &connections_get 
    get "/users/me/requests", &connections_requests_get
    get "/users/me/requests/:id", &connections_requests_get_by_id
    patch "/users/me/requests/:id", &user_connections_patch

    post "/users/:id/requests", &connections_request_post
    get "/users/:id/requests", &get_exist_request

    get "/users/me/aggregate-comments", allows: [:skillset_id, :role_id], &get_user_comments_created_by_skillset_and_roles_by_me
    get "/users/me/aggregate-votes", allows: [:skillset_id, :role_id], &get_user_votes_cast_by_skillset_and_roles_by_me
    get "/users/me/aggregate-contributors", allows: [:skillset_id, :role_id], &get_user_contributions_created_by_skillset_and_roles_by_me
    get "/users/me/aggregate-comments-received", allows: [:skillset_id, :role_id], &get_user_comments_received_by_skillset_and_roles_by_me
    get "/users/me/aggregate-votes-received", allows: [:skillset_id, :role_id], &get_user_votes_received_by_skillset_and_roles_by_me
    get "/users/me/aggregate-contributors-received", allows: [:skillset_id, :role_id], &get_user_contributions_selected_by_skillset_and_roles_by_me

    get "/users/:user_id/aggregate-comments", allows: [:user_id, :skillset_id, :role_id], needs: [:user_id], &get_user_comments_created_by_skillset_and_roles
    get "/users/:user_id/aggregate-votes", allows: [:user_id, :skillset_id, :role_id], needs: [:user_id], &get_user_votes_cast_by_skillset_and_roles
    get "/users/:user_id/aggregate-contributors", allows: [:user_id, :skillset_id, :role_id], needs: [:user_id], &get_user_contributions_created_by_skillset_and_roles
    get "/users/:user_id/aggregate-comments-received", allows: [:user_id, :skillset_id, :role_id], needs: [:user_id], &get_user_comments_received_by_skillset_and_roles
    get "/users/:user_id/aggregate-votes-received", allows: [:user_id, :skillset_id, :role_id], needs: [:user_id], &get_user_votes_received_by_skillset_and_roles
    get "/users/:user_id/aggregate-contributors-received", allows: [:user_id, :skillset_id, :role_id], needs: [:user_id], &get_user_contributions_selected_by_skillset_and_roles

    # do not add a /users request with a single namespace below this
    get "/users/me", &users_get_by_me #must precede :id request
    get "/users/:id", allows: [:id], needs: [:id], &users_get_by_id

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
    get "/projects/:id", allows: [:id], needs: [:id], &projects_get_by_id

    #    post "/projects/:project_id/refresh", &refresh_post #TODO - later
    post "/projects/:project_id/contributors", &contributors_post
    patch "/projects/:project_id/contributors/:contributor_id", &contributors_patch_by_id
    get "/projects/:project_id/contributors/:contributor_id", &contributors_get_by_id

    get "/sprints", allows: [:id, :project_id, "sprint_states.state_id"], &sprints_get
    get "/sprints/:id", allows: [:id], needs: [:id], &sprints_get_by_id
    post "/sprints", &sprints_post

    get "/sprint-states", allows: [:sprint_id, :id], &sprint_states_get
    post "/sprint-states", &sprint_states_post

    post "/contributors/:id/comments", &contributors_post_comments
    post "/contributors/:id/votes", &contributors_post_votes
    post "/contributors/:id/winner", &contributors_post_winner
    post "/contributors/:id/merge", &contributors_post_merge

    post "/teams", &teams_post
    get "/teams", &teams_get
    get "/teams/:id", allows: [:id], needs: [:id], &teams_get_by_id
    get "/team-invites", &team_invites_get

    get "/team/:id/connections", &team_connections_get 

    post "/user-teams/token", &user_teams_patch
    post "/user-teams", &user_teams_post
    get "/user-teams", allows: [:team_id,:seat_id], needs: [:team_id], &user_teams_get

    error RequiredParamMissing do
        [400, env['sinatra.error'].message]
    end

    # Ember
    get "*" do
        send_file File.expand_path('index.html',settings.public_folder)
    end
end

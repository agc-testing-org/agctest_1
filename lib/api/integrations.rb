require 'sinatra'
require 'mysql2'
require 'sinatra/base'
require 'sinatra/activerecord'
require 'activerecord-import'
require 'activerecord-import/base'
require 'sinatra/strong-params'
require 'json'
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
require 'aws-sdk'

#Helpers
require_relative '../helpers/obfuscate.rb'
require_relative '../helpers/slack.rb'
require_relative '../helpers/params_helper.rb'

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
require_relative '../models/notification.rb'
require_relative '../models/user_notification_setting.rb'
require_relative '../models/job.rb'

# Workers
require_relative '../workers/user_notification_worker.rb'
require_relative '../workers/contributor_join_worker.rb'
require_relative '../workers/contributor_sync_worker.rb'
require_relative '../workers/user_invite_worker.rb'
require_relative '../workers/user_password_reset_worker.rb'
require_relative '../workers/user_register_worker.rb'
require_relative '../workers/user_notification_get_worker.rb'
require_relative '../workers/user_notification_mail_worker.rb'
require_relative '../workers/user_create_project_worker.rb'

# Throttling
require_relative 'rack'

Sidekiq.configure_server do |config|
    config.redis = { url: "redis://#{ENV['INTEGRATIONS_REDIS_HOST']}:#{ENV['INTEGRATIONS_REDIS_PORT']}/#{ENV['INTEGRATIONS_REDIS_DB']}" }
end

Sidekiq.configure_client do |config|
    config.redis = { url: "redis://#{ENV['INTEGRATIONS_REDIS_HOST']}:#{ENV['INTEGRATIONS_REDIS_PORT']}/#{ENV['INTEGRATIONS_REDIS_DB']}" }
end

class Integrations < Sinatra::Base

    include Obfuscate

    set :database_file, "#{Dir.pwd}/config/database.yml"
    set :public_folder, File.expand_path('integrations-client/dist')

    if settings.production?
        Aws.config.update({
            region: ENV["AWS_REGION"],
            credentials: Aws::Credentials.new(ENV["AWS_ACCESS_KEY_ID"], ENV["AWS_SECRET_ACCESS_KEY"])
        })
    end

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


    before do
        #content_type :json  
        headers 'Access-Control-Allow-Origin' => ENV['INTEGRATIONS_SPLASH_HOST'],
            'Access-Control-Allow-Methods' => ['POST'],
            'Access-Control-Allow-Headers' => 'Content-Type'
    end


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

    def session_tokens user, seat_id, initial 

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

        session_hash = {:key => user_secret, :id => user[:id], :first_name => user[:first_name], :last_name => user[:last_name], :admin => user[:admin], :seat_id => seat_id, :github_username => github_username, :github_token => github_token}.to_json

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
            initial && (account.record_login user[:id], request.ip,  request.user_agent)
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
        (user = account.request_token fields[:email]) || (return_error "we couldn't find this email address")
        UserPasswordResetWorker.perform_async user.first_name, fields[:email], user.token
        status 201
        return {:success => true}.to_json
    end

    resend_invitation_post = lambda do
        fields = get_json
        account = Account.new
        check_required_field fields[:token], "token"
        invite = account.refresh_team_invite fields[:token]
        invite || (return_error "we couldn't find this invitation")
        UserInviteWorker.perform_async invite.token 
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
        UserRegisterWorker.perform_async user.email, user.first_name
        if fields[:roles].length < 5 #accept roles from people that sign up without an invite
            fields[:roles].each do |r|
                account.update_role decrypt(user.id), r[:id], r[:active]
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
        user_params = {:id => invitation.first[:user_id]}
        user = account.get user_params
        (account.confirm_user user, fields[:password], fields[:firstName], request.ip) || (return_error "unable to accept this invitation at this time")
        seat_id = account.get_seat_permissions user[:id]
        slack = Slack.new
        slack.post_accepted invitation.first
        status 200
        return (session_tokens user, seat_id, true).to_json
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
        seat_id = account.get_seat_permissions user[:id] 
        status 200
        return (session_tokens user, seat_id, true).to_json
    end

    login_post = lambda do
        fields = get_json
        check_required_field fields[:email], "password"
        check_required_field fields[:password], "password"
        account = Account.new
        user = account.sign_in fields[:email], fields[:password], request.ip
        user || (return_error "email or password incorrect")
        seat_id = account.get_seat_permissions user[:id] 
        status 200
        return (session_tokens user, seat_id, true).to_json
    end

    session_provider_linkedin_post = lambda do
        protected!
        fields = get_json
        account = Account.new
        filters = {:id => @session_hash["id"]}
        user = account.get filters
        user || return_unauthorized 
        fields[:auth_code] && (access_token = account.linkedin_code_for_token(fields[:auth_code]))
        #ALWAYS RETURN session tokens, even if conditions below fail
        #access_token || (return_error "invalid code")
        access_token && (linkedin = (account.linkedin_client access_token)) || (linkedin = nil)
        #linkedin || (return_error "invalid access token")
        linkedin && (pulled = account.pull_linkedin_profile linkedin)
        #pulled || (return_error "could not pull profile")
        linkedin && pulled && (profile_id = account.post_linkedin_profile @session_hash["id"], pulled)
        (linkedin && profile_id && pulled && pulled.positions && pulled.positions.all && (pulled.positions.all.length > 0) && (account.post_linkedin_profile_position profile_id, pulled.positions.all[0])) #|| (return_error "could not save profile")
        response = (session_tokens user, @session_hash["seat_id"], false) 
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
        (github && (@session_hash["github_username"] = github.login)) || (@session_hash["github_username"] = nil)
        provider_token = account.create_token @session_hash["id"], @key, access_token 
        @session_hash["github_token"] = provider_token
        response = (session_tokens user, @session_hash["seat_id"], false)
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
        seat_id = account.get_seat_permissions user[:id] 
        ((@session = user.jwt) && authorized?) #get session if exists to preserve github token
        status 200
        return (session_tokens user, seat_id, false).to_json
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
        return {:id => encrypt(@session_hash["id"]), :first_name => @session_hash["first_name"], :last_name => @session_hash["last_name"], :admin => @session_hash["admin"], :seat_id => @session_hash["seat_id"], :github => !@session_hash["github_token"].nil?, :github_username => @session_hash["github_username"]}.to_json
    end

    users_get_by_id = lambda do
        @session = retrieve_token
        authorized?
        account = Account.new 
        params["id"] = decrypt params["id"]
        user = account.get params
        user || return_not_found
        response = {
            :id => user.id, 
            :created_at => user.created_at,
        }
        if user.user_profile && user.user_profile.user_position
            response[:location] = user.user_profile.location_name
            response[:title] = user.user_profile.user_position.title
            response[:industry] = user.user_profile.user_position.industry
            response[:size] = user.user_profile.user_position.size
            response[:company] = (user.user_profile.user_position.company if ( @session_hash && (@session_hash["id"] == user[:id])))
        end 
        status 200
        return response.to_json 
    end

    users_get_by_me = lambda do
        protected!
        redirect to("/users/#{encrypt(@session_hash["id"])}")
    end

    users_roles_get = lambda do
        account = Account.new
        status 200
        return (account.get_roles decrypt(params[:user_id]), nil).to_json
    end

    users_roles_get_by_me = lambda do
        protected!
        redirect to("/users/#{encrypt(@session_hash["id"])}/roles")
    end

    users_roles_get_by_role = lambda do
        protected!
        check_required_field params[:role_id], "role_id"
        account = Account.new
        query = {:id => params[:role_id]}
        status 200
        return (account.get_roles @session_hash["id"], query)[0].to_json
    end

    users_roles_patch_by_id = lambda do
        protected!
        check_required_field params[:role_id], "role_id"
        fields = get_json
        check_required_field !fields[:active].nil?, "active"
        account = Account.new
        response = (account.update_role @session_hash["id"], params[:role_id], fields[:active])
        response || (return_error "unable not update role")
        status 200
        return response.to_json
    end

    roles_get = lambda do
        account = Account.new
        status 200
        return Role.all.order(:name).to_json rescue (return_error "unable to find roles")
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
        account = Account.new
        status 200
        return (account.get_skillsets decrypt(params[:user_id]), nil).to_json
    end

    users_skillsets_get_by_me = lambda do
        protected!
        redirect to("/users/#{encrypt(@session_hash["id"])}/skillsets")
    end

    users_skillsets_get_by_skillset = lambda do
        protected!
        check_required_field params[:skillset_id], "skillset_id"
        account = Account.new
        query = {:id => params[:skillset_id]}
        status 200
        return (account.get_skillsets @session_hash["id"], query)[0].to_json
    end

    users_skillsets_patch = lambda do
        protected!
        check_required_field params[:skillset_id], "skillset_id"
        fields = get_json
        check_required_field !fields[:active].nil?, "active"  
        account = Account.new
        response = (account.update_skillset @session_hash["id"], params[:skillset_id], fields[:active])
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
                    :owner => repo.owner.login,
                    :description => repo.description
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

    projects_patch_by_id = lambda do
        protected!
        @session_hash["admin"] || return_unauthorized_admin
        fields = get_json
        check_required_field fields[:caption], "caption"
        caption_length = fields[:caption].to_s.length
        (caption_length < 501 && caption_length > 4) || (return_error "caption must be 5-500 characters")
        issue = Issue.new
        project = issue.get_projects params
        (project && project.first) || return_not_found 
        project.first.caption = fields[:caption]
        project.first.save
        return project.first.to_json
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
        project = issue.create_project @session_hash["id"], fields[:org], fields[:name], fields[:description]

        repo = Repo.new
        github = (repo.github_client ENV['INTEGRATIONS_GITHUB_ADMIN_SECRET'])
        github || (return_error "unable to authenticate github")
        github.create_repo("#{project.name}_#{project.id}", {:organization => ENV['INTEGRATIONS_GITHUB_ORG']}) || (return_error "unable to create project")

        UserCreateProjectWorker.perform_async project.id

        status 201
        return project.to_json
    end

    teams_get = lambda do
        protected!
        account = Account.new
        status 200
        return (account.get_teams @session_hash["id"], params).to_json
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
        team_response["shares"] = (seat && (seat == "share"))
        team_response["seats"] = allowed_seats
        if team.plan
            team_response["plan"] = team.plan
            team_response["default_seat_id"] = team.plan.seat.id
        end
        status 200
        return team_response.to_json
    end

    teams_notifications_get = lambda do
        protected!
        account = Account.new
        seat = account.get_seat @session_hash["id"], params["id"]
        ((seat && (seat == "member")) || @session_hash["admin"]) || return_not_found
        status 200
        org = Organization.new
        return (org.get_team_notifications params).to_json
    end

    teams_post = lambda do
        protected!
        fields = get_json
        check_required_field fields[:name], "name"
        check_required_field fields[:plan_id], "plan_id"
        name_length = fields[:name].to_s.length
        account = Account.new
        (name_length < 31 && name_length > 1) || (return_error "team name must be 2-30 characters") 
        (Plan.find_by(:id => fields[:plan_id])) || (return_error "invalid plan_id")
        query = {:id => @session_hash["id"]}
        user = account.get query
        ((user.user_profile && user.user_profile.user_position) && company = user.user_profile.user_position.company) || (return_error "you must connect linkedin to create a team")
        org = Organization.new
        team = org.create_team fields[:name], @session_hash["id"], fields[:plan_id], company
        (team && team.id) || (team.errors.messages[:name] && (return_error team.errors.messages[:name][0]))
        (org.add_owner @session_hash["id"], team["id"]) || (return_error "unable to create team")
        status 201
        return team.to_json
    end

    jobs_get = lambda do
        org = Organization.new
        jobs = org.get_jobs params
        jobs || (return_error "unable to find jobs")
        jobs_with_sprints = org.jobs_with_sprints jobs
        jobs_with_sprints || (return_error "unable to find jobs")
        status 200
        return jobs_with_sprints.to_json
    end

    jobs_get_by_id = lambda do
        org = Organization.new
        jobs = org.get_jobs params
        (jobs && jobs.first) || return_not_found
        jobs_with_sprints = org.jobs_with_sprints jobs
        (jobs_with_sprints && jobs_with_sprints.first) || (return_error "unable to find job")
        status 200
        return jobs_with_sprints.first.to_json
    end

    jobs_patch_by_id = lambda do
        protected!
        fields = get_json
        check_required_field fields[:team_id], "team_id"
        check_required_field fields[:sprint_id], "sprint_id"

        account = Account.new
        seat = account.get_seat @session_hash["id"], fields[:team_id]
        ((seat && (seat == "member")) || @session_hash["admin"]) || return_unauthorized

        org = Organization.new
        query = {:id => params[:id], :team_id => fields[:team_id]}
        jobs = org.get_jobs query
        (jobs && jobs.first) || return_not_found
        saved = jobs.first.update_attributes!(:sprint_id => fields[:sprint_id])
        saved || (return_error "unable to select idea")

        fields[:state] = State.find_by({:name => "requirements design"}).id
        fields[:sprint] = fields[:sprint_id]

        sprint_state = sprint_states_post_helper fields

        status 200
        return jobs.first.to_json
    end

    jobs_post = lambda do
        protected!
        fields = get_json
        check_required_field fields[:team_id], "team_id"
        check_required_field fields[:role_id], "role_id"
        check_required_field fields[:link], "link"
        check_required_field fields[:title], "title"
        check_required_field fields[:zip], "zip"

        account = Account.new
        seat = account.get_seat @session_hash["id"], fields[:team_id]
        ((seat && (seat == "member")) || @session_hash["admin"]) || return_unauthorized

        title_length = fields[:title].to_s.length
        (title_length < 101 && title_length > 4) || (return_error "title must be 5-100 characters")

        zip_length = fields[:zip].to_s.length
        (zip_length < 7 && zip_length > 4) || (return_error "a valid zip code is required")

        (fields[:link].to_s.include? "http") || (return_error "a full link (http or https is required)")

        org = Organization.new
        job = org.create_job @session_hash["id"], fields[:team_id], fields[:role_id], fields[:title], fields[:link], fields[:zip]
        job || (return_error "unable to create job listing")

        issue = Issue.new
        log_params = {:user_id => @session_hash["id"], :job_id => job.id, :notification_id => Notification.find_by({:name => "job"}).id}
        (issue.log_event log_params) || (return_error "unable to create job")
        status 201
        return job.to_json
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
        sprint = issue.create @session_hash["id"], fields[:title],  fields[:description],  fields[:project_id], fields[:job_id]
        sprint || (return_error "unable to create sprint for this project")

        state = State.find_by(:name => "idea").id
        sprint_state = issue.create_sprint_state sprint.id, state, nil
        sprint_state || (return_error "unable to create sprint")
        log_params = {:sprint_id => sprint.id, :state_id => state, :user_id => @session_hash["id"], :job_id => fields[:job_id], :project_id => fields[:project_id], :sprint_state_id => sprint_state.id, :notification_id => Notification.find_by({:name => "new"}).id}
        (issue.log_event log_params) || (return_error "unable to create sprint")
        status 201
        sprint_json = sprint.as_json
        sprint_json[:project] = sprint.project_id
        return sprint.to_json
    end

    def sprint_states_post_helper fields
        issue = Issue.new
        sprint = (issue.get_sprint fields[:sprint])
        sprint || return_not_found
        repo = Repo.new
        github = (repo.github_client ENV["INTEGRATIONS_GITHUB_ADMIN_SECRET"])
        sprint || (return_error "unable to connect to github")
        sha = github.branch("#{ENV['INTEGRATIONS_GITHUB_ORG']}/#{sprint.project.name}_#{sprint.project.id}","master").commit.sha
        sha || (return_error "unable to retrieve sha")
        sprint_state = issue.create_sprint_state fields[:sprint], fields[:state], sha
        sprint_state || (return_error "unable to create sprint state")
        log_params = {:sprint_id => fields[:sprint], :state_id => fields[:state], :user_id => @session_hash["id"], :project_id => sprint.project.id, :sprint_state_id => sprint_state.id, :notification_id => Notification.find_by({:name => "transition"}).id}
        (issue.log_event log_params) ||  (return_error "unable to create sprint state")
        return sprint_state
    end

    sprint_states_post = lambda do
        protected!
        @session_hash["admin"] || return_unauthorized_admin
        fields = get_json
        check_required_field fields[:state], "state"
        check_required_field fields[:sprint], "sprint"

        sprint_state = sprint_states_post_helper fields

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
        sprint_state = issue.get_sprint_state fields[:sprint_state_id]

        (params[:id] || sprint_state.state.name == "idea") || return_error "unable to comment on this item"
        comment = issue.create_comment @session_hash["id"], params[:id], fields[:sprint_state_id], fields[:text], fields[:explain]
        comment || (return_error "unable to save comment")
        
        sprint_ids = issue.get_sprint_state_ids_by_sprint sprint_state.sprint_id
        next_sprint_state_id = issue.get_next_sprint_state sprint_state.id, sprint_ids

        log_params = {:comment_id => comment.id, :project_id => sprint_state.sprint.project.id, :sprint_id => sprint_state.sprint_id, :state_id => sprint_state.state_id, :sprint_state_id =>  sprint_state.id, :next_sprint_state_id => next_sprint_state_id, :user_id => @session_hash["id"], :contributor_id => params[:id], :notification_id => Notification.find_by({:name => "comment"}).id}

        (sprint_state.state.name == "idea") && (log_params[:notification_id] => Notification.find_by({:name => "sprint comment"}).id})

        (issue.log_event log_params) || (return_error "an error has occurred")
        status 201
        return comment.to_json
    end

    contributors_post_votes = lambda do
        protected!
        fields = get_json
        check_required_field fields[:sprint_state_id], "sprint_state_id"
        issue = Issue.new
        if params[:id]
            vote = issue.vote @session_hash["id"], params[:id], fields[:sprint_state_id], fields[:comment_id], fields[:flag]
            vote || (return_error "unable to save vote")
            vote[:created] || (halt 200, vote.to_json) # vote already cast, don't save another event
            sprint_state = issue.get_sprint_state fields[:sprint_state_id]
            sprint_ids = issue.get_sprint_state_ids_by_sprint sprint_state.sprint_id
            next_sprint_state_id = issue.get_next_sprint_state sprint_state.id, sprint_ids
            if vote["id"] != nil
                if fields[:comment_id] && fields[:flag]
                    log_params = {:vote_id => vote["id"], :project_id => sprint_state.sprint.project.id, :sprint_id => sprint_state.sprint_id, :state_id => sprint_state.state_id, :sprint_state_id =>  sprint_state.id, :next_sprint_state_id => next_sprint_state_id, :user_id => @session_hash["id"], :contributor_id => params[:id], :notification_id => Notification.find_by({:name => "comment offensive"}).id}
                elsif fields[:comment_id]
                    log_params = {:vote_id => vote["id"], :project_id => sprint_state.sprint.project.id, :sprint_id => sprint_state.sprint_id, :state_id => sprint_state.state_id, :sprint_state_id =>  sprint_state.id, :next_sprint_state_id => next_sprint_state_id, :user_id => @session_hash["id"], :contributor_id => params[:id], :notification_id => Notification.find_by({:name => "comment vote"}).id}
                else
                    log_params = {:vote_id => vote["id"], :comment_id => vote["comment_id"], :project_id => sprint_state.sprint.project.id, :sprint_id => sprint_state.sprint_id, :state_id => sprint_state.state_id, :sprint_state_id =>  sprint_state.id, :next_sprint_state_id => next_sprint_state_id, :user_id => @session_hash["id"], :contributor_id => params[:id], :notification_id => Notification.find_by({:name => "vote"}).id}
                end
            end
            (issue.log_event log_params) || (return_error "an error has occurred")
        else
            sprint_state = issue.get_sprint_state fields[:sprint_state_id]
            state = State.find_by(:name => "idea").id
            if sprint_state.state_id == state
                vote = issue.vote @session_hash["id"], nil, fields[:sprint_state_id], fields[:comment_id], fields[:flag]
                vote || (return_error "unable to save vote")
                vote[:created] || (halt 200, vote.to_json) # vote already cast, don't save another event
                sprint_ids = issue.get_sprint_state_ids_by_sprint sprint_state.sprint_id
                next_sprint_state_id = issue.get_next_sprint_state sprint_state.id, sprint_ids
                if vote["id"] != nil
                    if fields[:comment_id] && fields[:flag]
                        log_params = {:vote_id => vote["id"], :project_id => sprint_state.sprint.project.id, :sprint_id => sprint_state.sprint_id, :state_id => sprint_state.state_id, :sprint_state_id =>  sprint_state.id, :next_sprint_state_id => next_sprint_state_id, :user_id => @session_hash["id"], :contributor_id => params[:id], :notification_id => Notification.find_by({:name => "sprint comment offensive"}).id}
                    elsif fields[:comment_id]
                        log_params = {:vote_id => vote["id"], :project_id => sprint_state.sprint.project.id, :sprint_id => sprint_state.sprint_id, :state_id => sprint_state.state_id, :sprint_state_id =>  sprint_state.id, :next_sprint_state_id => next_sprint_state_id, :user_id => @session_hash["id"], :contributor_id => params[:id], :notification_id => Notification.find_by({:name => "sprint comment vote"}).id}
                    else
                        log_params = {:vote_id => vote["id"], :comment_id => vote["comment_id"], :project_id => sprint_state.sprint.project.id, :sprint_id => sprint_state.sprint_id, :state_id => sprint_state.state_id, :sprint_state_id =>  sprint_state.id, :next_sprint_state_id => next_sprint_state_id, :user_id => @session_hash["id"], :contributor_id => params[:id], :notification_id => Notification.find_by({:name => "sprint vote"}).id}
                    end
                end
            end
            (issue.log_event log_params) || (return_error "an error has occurred")
        end
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
        (pr = github.create_pull_request("#{ENV['INTEGRATIONS_GITHUB_ORG']}/#{sprint_state.sprint.project.name}_#{sprint_state.sprint.project.id}", "master", "#{fields[:sprint_state_id].to_i}_#{params[:id].to_i}", "Wired7 #{fields[:sprint_state_id].to_i}_#{params[:id].to_i} to master", body = nil, options = {})) rescue (return_error "unable to create pull request") # could exist already
        parameters = {arbiter_id: @session_hash["id"], contributor_id: params[:id], pull_request: pr.number}
        sprint_state.update_attributes!(parameters) rescue (return_error "unable to set winner") 
        sprint_ids = issue.get_sprint_state_ids_by_sprint sprint_state.sprint_id
        next_sprint_state_id = issue.get_next_sprint_state sprint_state.id, sprint_ids
        log_params = {:sprint_id => sprint_state.sprint_id, :sprint_state_id => sprint_state.id, :next_sprint_state_id => next_sprint_state_id, :user_id => @session_hash["id"], :project_id => sprint_state.sprint.project.id, :contributor_id => params[:id], :notification_id => Notification.find_by({:name => "winner"}).id}
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
        pr = github.merge_pull_request("#{ENV['INTEGRATIONS_GITHUB_ORG']}/#{winner.sprint.project.name}_#{winner.sprint.project.id}", winner.pull_request, commit_message = "Wired7 #{winner.id}_#{winner.contributor_id} to master", options = {})
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

        query = {"sprints.project_id" => sprint_state.sprint.project_id, :user_id => @session_hash["id"] } #check for project, not sprint state
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

        ContributorJoinWorker.perform_async @session, @session_hash["github_token"], created, username

        status 201
        return {:id => created, :preparing => 1}.to_json
    end

    contributors_patch_by_id = lambda do
        protected!
        repo = Repo.new
        check_required_field params[:contributor_id], "contributor_id"
        query = {:id => params[:contributor_id], :user_id => @session_hash["id"] }
        contributor = repo.get_contributor query
        contributor || return_not_found
        github = (repo.github_client github_authorization)
        github || (return_error "unable to authenticate github")
        contributor.preparing = true
        contributor.prepared = 0
        contributor.save
        ContributorSyncWorker.perform_async contributor[:id], @session_hash["github_username"]
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
        id = decrypt(params[:id]) || return_not_found
        account = Account.new
        status 201
        return (account.create_connection_request @session_hash["id"], id).to_json
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
        id = decrypt(params[:id]) || (halt 200, {:id => 0}.to_json)  
        query = {"user_connections.contact_id" => id, :user_id => @session_hash["id"]} 
        outgoing = account.get_user_connections query
        query = {"user_connections.user_id" => id, "user_connections.contact_id" => @session_hash["id"]}
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
        query = {:id => params[:id], :contact_id => @session_hash["id"]} 
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
        return (account.update_user_connections @session_hash["id"], decrypt(fields[:user_id]), fields[:read], fields[:confirmed]).to_json
    end

    user_teams_get_comments = lambda do
        protected!
        check_required_field params["team_id"], "team_id"
        account = Account.new
        seat = account.get_seat @session_hash["id"], params["team_id"]
        ((seat && (seat == "member")) || @session_hash["admin"]) || return_not_found
        feedback = Feedback.new
        filter = {}
        requests = feedback.sprint_timeline_comments_created
        requests || (return_error "unable to retrieve comments")
        team = Organization.new
        team_requests = team.get_sprint_timeline_aggregate_counts requests, params
        return team_requests.to_json
    end

    user_teams_get_votes = lambda do
        protected!
        check_required_field params["team_id"], "team_id"
        account = Account.new
        seat = account.get_seat @session_hash["id"], params["team_id"]
        ((seat && (seat == "member")) || @session_hash["admin"]) || return_not_found
        feedback = Feedback.new
        filter = {}
        requests = feedback.sprint_timeline_votes_cast
        requests || (return_error "unable to retrieve votes")
        team = Organization.new
        team_requests = team.get_sprint_timeline_aggregate_counts requests, params
        return team_requests.to_json
    end 

    user_teams_get_contributors = lambda do
        protected!
        check_required_field params["team_id"], "team_id"
        account = Account.new
        seat = account.get_seat @session_hash["id"], params["team_id"]
        ((seat && (seat == "member")) || @session_hash["admin"]) || return_not_found
        feedback = Feedback.new
        filter = {}
        requests = feedback.sprint_timeline_contributions
        requests || (return_error "unable to retrieve contributions")
        team = Organization.new
        team_requests = team.get_contributor_aggregate_counts requests, params
        return team_requests.to_json
    end 

    user_teams_get_comments_received = lambda do
        protected!
        check_required_field params["team_id"], "team_id"
        account = Account.new
        seat = account.get_seat @session_hash["id"], params["team_id"]
        ((seat && (seat == "member")) || @session_hash["admin"]) || return_not_found
        feedback = Feedback.new
        filter = {}
        requests = feedback.sprint_timeline_comments_received
        requests || (return_error "unable to retrieve comments received")
        team = Organization.new
        team_requests = team.get_sprint_timeline_aggregate_counts requests, params
        return team_requests.to_json
    end

    user_teams_get_votes_received = lambda do
        protected!
        check_required_field params["team_id"], "team_id"
        account = Account.new
        seat = account.get_seat @session_hash["id"], params["team_id"]
        ((seat && (seat == "member")) || @session_hash["admin"]) || return_not_found
        feedback = Feedback.new
        filter = {}
        requests = feedback.sprint_timeline_votes_received
        requests || (return_error "unable to retrieve votes received")
        team = Organization.new
        team_requests = team.get_sprint_timeline_aggregate_counts requests, params                          
        return team_requests.to_json                                                                
    end                                                                                                 

    user_teams_get_contributors_received = lambda do
        protected!
        check_required_field params["team_id"], "team_id"
        account = Account.new
        seat = account.get_seat @session_hash["id"], params["team_id"]
        ((seat && (seat == "member")) || @session_hash["admin"]) || return_not_found
        feedback = Feedback.new                     
        filter = {}                                         
        requests = feedback.sprint_timeline_contributions_winner
        requests || (return_error "unable to retrieve winning contributions")
        team = Organization.new                                                     
        team_requests = team.get_sprint_timeline_aggregate_counts requests, params                          
        return team_requests.to_json                                                                
    end  

    user_teams_patch = lambda do
        protected!
        fields = get_json
        check_required_field fields[:token], "token"
        account = Account.new
        invitation = account.get_invitation fields[:token]
        (invitation.first && invitation.first.user_id) || (return_error "this invitation is invalid")
        (@session_hash["id"] == decrypt(invitation.first.user_id).to_i) || (return_error "this invitation is invalid")
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
        (profile_id = decrypt(fields[:profile_id])) || (profile_id = nil)
        invitation = team.invite_member fields[:team_id], @session_hash["id"], user[:id], user[:email], fields[:seat_id], profile_id, fields[:job_id]
        invitation || (return_error "invite error")
        invitation.id || (return_error "this email address has an existing invitation")
        UserInviteWorker.perform_async invitation.token
        invitation = invitation.as_json
        invitation.delete("token")
        status 201
        return invitation.to_json
    end

    team_invites_get = lambda do
        check_required_field params[:token], "token"
        account = Account.new
        invite = account.get_invitation params[:token]
        (invite && invite.first) || (halt 200, {:id => 0, :valid => false}.to_json)
        team = Organization.new
        (team.invite_expired? invite) || (halt 200, {:id => invite.first.id, expired: true, valid: true}.to_json)
        status 200
        return {
            id: invite.first.id,
            registered: invite.first.user.confirmed,
            valid: true,
            expired: false,
            name: invite.first.team.name,
            company: invite.first.team.company
        }.to_json
    end

    shares_post = lambda do
        protected!
        fields = get_json
        check_required_field fields[:token], "token"
        account = Account.new
        invite = account.get_invitation fields[:token]
        (invite = invite.first) || (halt 200, {:id => 0, :valid => false}.to_json)
        invite.accepted = true
        invite.token = nil
        return {:id => invite.id, :valid => invite.save}.to_json
    end

    teams_shares_get = lambda do
        protected!
        check_required_field params["team_id"], "team_id"
        account = Account.new
        seat = account.get_seat @session_hash["id"], params["team_id"]
        ((seat && (seat == "share")) || @session_hash["admin"]) || return_not_found
        org = Organization.new
        status 200                  
        return (org.get_shares @session_hash["id"], params).to_json
    end  

    get_user_notifications = lambda do
        protected!
        account = Account.new
        status 200
        return (account.get_user_notifications @session_hash["id"], params).to_json
    end

    get_user_notifications_by_id = lambda do
        protected!
        check_required_field params[:id], "id"
        account = Account.new
        response = (account.get_user_notifications_by_id @session_hash["id"], params[:id])
        response || return_not_found
        status 200
        return {:data => response, :meta => {}}.to_json
    end

    user_notifications_read = lambda do
        protected!
        check_required_field params[:id], "id"
        account = Account.new
        notification = account.get_user_notifications_by_id @session_hash["id"], params[:id]
        response || return_not_found
        notification.read = true 
        notification.save
        status 200
        return {:data => notification, :meta => {}}.to_json
    end

    get_user_notifications_settings = lambda do
        protected!
        account = Account.new
        status 200
        return (account.get_user_notifications_settings @session_hash["id"], nil).to_json
    end

    get_user_notifications_settings_by_id = lambda do
        protected!
        check_required_field params[:notification_id], "notification_id"
        account = Account.new
        query = {:id => params[:notification_id]}
        status 200
        return (account.get_user_notifications_settings @session_hash["id"], query)[0].to_json
    end

    user_notifications_settings_patch = lambda do
        protected!
        check_required_field params[:notification_id], "notification_id"
        fields = get_json
        check_required_field !fields[:active].nil?, "active"  
        account = Account.new
        response = (account.update_user_notifications_settings @session_hash["id"], params[:notification_id], fields[:active])
        response || (return_error "unable to update notification_settings")
        status 200
        return response.to_json
    end

    get_user_comments_created_by_skillset_and_roles = lambda do
        feedback = Feedback.new
        params["user_id"] = decrypt(params["user_id"])
        requests = feedback.user_comments_created_by_skillset_and_roles params
        requests || (return_error "unable to retrieve comments") 
        return {:meta => {:count => (feedback.get_count requests)}, :data => (feedback.build_feedback requests)}.to_json
    end

    get_user_comments_received_by_skillset_and_roles = lambda do
        feedback = Feedback.new
        params["user_id"] = decrypt(params["user_id"])
        requests = feedback.user_comments_received_by_skillset_and_roles params
        requests || (return_error "unable to retrieve comments") 
        return {:meta => {:count => (feedback.get_count requests)}, :data => (feedback.build_feedback requests)}.to_json 
    end

    get_user_votes_cast_by_skillset_and_roles = lambda do
        feedback = Feedback.new
        params["user_id"] = decrypt(params["user_id"])
        requests = feedback.user_votes_cast_by_skillset_and_roles params
        requests || (return_error "unable to retrieve votes")
        return {:meta => {:count => (feedback.get_count requests)}, :data => (feedback.build_feedback requests)}.to_json 
    end

    get_user_votes_received_by_skillset_and_roles = lambda do
        feedback = Feedback.new
        params["user_id"] = decrypt(params["user_id"])
        requests = feedback.user_votes_received_by_skillset_and_roles params
        requests || (return_error "unable to retrieve votes")
        return {:meta => {:count => (feedback.get_count requests)}, :data => (feedback.build_feedback requests)}.to_json 
    end

    get_user_contributions_created_by_skillset_and_roles = lambda do
        feedback = Feedback.new
        params["user_id"] = decrypt(params["user_id"]) 
        requests = feedback.user_contributions_created_by_skillset_and_roles params
        requests || (return_error "unable to retrieve contribution")
        return {:meta => {:count => (feedback.get_count requests)}, :data => (feedback.build_contribution_feedback requests)}.to_json 
    end

    get_user_contributions_selected_by_skillset_and_roles = lambda do
        feedback = Feedback.new
        params["user_id"] = decrypt(params["user_id"])
        requests = feedback.user_contributions_selected_by_skillset_and_roles params
        requests || (return_error "unable to retrieve winner")
        return {:meta => {:count => (feedback.get_count requests)}, :data => (feedback.build_feedback requests)}.to_json
    end

    get_user_comments_created_by_skillset_and_roles_by_me = lambda do
        protected!
        url = "/users/#{encrypt(@session_hash["id"])}/aggregate-comments?#{params.to_param}"
        redirect to url
    end

    get_user_votes_cast_by_skillset_and_roles_by_me = lambda do
        protected!
        url = "/users/#{encrypt(@session_hash["id"])}/aggregate-votes?#{params.to_param}"
        redirect to url
    end

    get_user_contributions_created_by_skillset_and_roles_by_me = lambda do
        protected!
        url = "/users/#{encrypt(@session_hash["id"])}/aggregate-contributors?#{params.to_param}"
        redirect to url
    end

    get_user_comments_received_by_skillset_and_roles_by_me = lambda do
        protected!
        url = "/users/#{encrypt(@session_hash["id"])}/aggregate-comments-received?#{params.to_param}"
        redirect to url
    end

    get_user_votes_received_by_skillset_and_roles_by_me = lambda do
        protected!
        url = "/users/#{encrypt(@session_hash["id"])}/aggregate-votes-received?#{params.to_param}"
        redirect to url
    end

    get_user_contributions_selected_by_skillset_and_roles_by_me = lambda do
        protected!
        url = "/users/#{encrypt(@session_hash["id"])}/aggregate-contributors-received?#{params.to_param}"
        redirect to url
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

    get "/users/me/notifications", allows: [:page], &get_user_notifications
    patch "/users/me/notifications/:id", &user_notifications_read
    get "/users/me/notifications/:id", &get_user_notifications_by_id
    get "/users/me/notifications-settings", &get_user_notifications_settings
    patch "/users/me/notifications-settings/:notification_id", &user_notifications_settings_patch
    get "/users/me/notifications-settings/:notification_id", &get_user_notifications_settings_by_id

    get "/users/me/connections", &connections_get 
    get "/users/me/requests", &connections_requests_get
    get "/users/me/connections/:id", &connections_requests_get_by_id
    patch "/users/me/connections/:id", &user_connections_patch

    post "/users/:id/requests", &connections_request_post
    get "/users/:id/requests", &get_exist_request

    get "/users/me/aggregate-comments", allows: [:page, :skillset_id, :role_id], &get_user_comments_created_by_skillset_and_roles_by_me
    get "/users/me/aggregate-votes", allows: [:page, :skillset_id, :role_id], &get_user_votes_cast_by_skillset_and_roles_by_me
    get "/users/me/aggregate-contributors", allows: [:page, :skillset_id, :role_id], &get_user_contributions_created_by_skillset_and_roles_by_me
    get "/users/me/aggregate-comments-received", allows: [:page, :skillset_id, :role_id], &get_user_comments_received_by_skillset_and_roles_by_me
    get "/users/me/aggregate-votes-received", allows: [:page, :skillset_id, :role_id], &get_user_votes_received_by_skillset_and_roles_by_me
    get "/users/me/aggregate-contributors-received", allows: [:page, :skillset_id, :role_id], &get_user_contributions_selected_by_skillset_and_roles_by_me

    get "/users/:user_id/aggregate-comments", allows: [:page, :user_id, :skillset_id, :role_id], needs: [:user_id], &get_user_comments_created_by_skillset_and_roles
    get "/users/:user_id/aggregate-votes", allows: [:page, :user_id, :skillset_id, :role_id], needs: [:user_id], &get_user_votes_cast_by_skillset_and_roles
    get "/users/:user_id/aggregate-contributors", allows: [:page, :user_id, :skillset_id, :role_id], needs: [:user_id], &get_user_contributions_created_by_skillset_and_roles
    get "/users/:user_id/aggregate-comments-received", allows: [:page, :user_id, :skillset_id, :role_id], needs: [:user_id], &get_user_comments_received_by_skillset_and_roles
    get "/users/:user_id/aggregate-votes-received", allows: [:page, :user_id, :skillset_id, :role_id], needs: [:user_id], &get_user_votes_received_by_skillset_and_roles
    get "/users/:user_id/aggregate-contributors-received", allows: [:page, :user_id, :skillset_id, :role_id], needs: [:user_id], &get_user_contributions_selected_by_skillset_and_roles

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
    patch "/projects/:id", allows: [:id], needs: [:id], &projects_patch_by_id

    #    post "/projects/:project_id/refresh", &refresh_post #TODO - later
    post "/contributors", &contributors_post
    patch "/contributors/:contributor_id", &contributors_patch_by_id
    get "/contributors/:contributor_id", &contributors_get_by_id

    get "/sprints", allows: [:id, :project_id, "sprint_states.state_id"], &sprints_get
    get "/sprints/:id", allows: [:id], needs: [:id], &sprints_get_by_id
    post "/sprints", &sprints_post
    post "/sprints/comments", &contributors_post_comments
    post "/sprints/votes", &contributors_post_votes

    get "/sprint-states", allows: [:sprint_id, :id], &sprint_states_get
    post "/sprint-states", &sprint_states_post

    post "/contributors/:id/comments", &contributors_post_comments
    post "/contributors/:id/votes", &contributors_post_votes
    post "/contributors/:id/winner", &contributors_post_winner
    post "/contributors/:id/merge", &contributors_post_merge


    get "/jobs", allows: [:id, :team_id], &jobs_get
    post "/jobs", &jobs_post
    get "/jobs/:id", allows: [:id], &jobs_get_by_id
    patch "/jobs/:id", &jobs_patch_by_id

    post "/teams", &teams_post
    get "/teams", allows: [:seat_id], &teams_get
    get "/teams/:id", allows: [:id], needs: [:id], &teams_get_by_id
    get "/team-invites", &team_invites_get

    get "/teams/:id/notifications", allows: [:id, :page], needs: [:id], &teams_notifications_get
    get "/teams/:id/shares", allows: [:team_id], needs: [:team_id], &teams_shares_get

    post "/shares", &shares_post

    post "/user-teams/token", &user_teams_patch
    post "/user-teams", &user_teams_post

    get "/user-teams", allows: [:team_id,:seat_id], needs: [:team_id], &user_teams_get
    get "/user-teams/:team_id/team-comments", allows: [:team_id,:seat_id], needs: [:team_id], &user_teams_get_comments
    get "/user-teams/:team_id/team-votes", allows: [:team_id,:seat_id], needs: [:team_id], &user_teams_get_votes
    get "/user-teams/:team_id/team-contributors", allows: [:team_id,:seat_id], needs: [:team_id], &user_teams_get_contributors

    get "/user-teams/:team_id/team-comments-received", allows: [:team_id,:seat_id], needs: [:team_id], &user_teams_get_comments_received
    get "/user-teams/:team_id/team-votes-received", allows: [:team_id,:seat_id], needs: [:team_id], &user_teams_get_votes_received
    get "/user-teams/:team_id/team-contributors-received", allows: [:team_id,:seat_id], needs: [:team_id], &user_teams_get_contributors_received

    error RequiredParamMissing do
        [400, env['sinatra.error'].message]
    end

    # Ember
    get "*" do
        content_type 'text/html'
        if ENV["RACK_ENV"] == "production"
            client = Aws::S3::Client.new
            index_version = ("index.html:#{params[:s3_version]}" if !params[:s3_version].nil?) || "index.html"
            return client.get_object({
                bucket: ENV["INTEGRATIONS_S3_BUCKET"], 
                key: index_version
            }).body.read
        else
            send_file File.expand_path('index.html',settings.public_folder)
        end
    end
end

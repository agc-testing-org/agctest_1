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
require 'git'




require 'sidekiq'
require 'whenever'

# Controllers
require_relative '../controllers/account.rb'
require_relative '../controllers/issue.rb'
require_relative '../controllers/repo.rb'
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
            account = Account.new
            puts "::unlocking github token"
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
                        update_fields = {
                            ip: request.ip,
                            jwt: jwt
                        }
                        if (account.save_token "session", jwt, {:key => user_secret, :id => user[:id], :name => user[:name], :admin => user[:admin], :github_username => user[:github_username]}.to_json) && (account.update user[:id], update_fields) && (account.record_login user[:id], request.ip)
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
                update_fields = {
                    ip: request.ip, 
                    jwt: jwt                        
                }  
                if (account.save_token "session", jwt, {:key => user_secret, :id => user[:id], :name => user[:name], :admin => user[:admin], :github_username => user[:github_username]}.to_json) && (account.update user[:id], update_fields) && (account.record_login user[:id], request.ip)
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

                repo = Repo.new
                github = (repo.github_client access_token)
                username = github.login

                provider_token = account.create_token @session_hash["id"], @key, access_token
                update_fields = {
                    github_username: username 
                }  
                if (account.save_token "session", @session, {:key => @key, :id => @session_hash["id"], :name => @session_hash["name"], :admin => @session_hash["admin"], :github => true, :github_username => username}.to_json) && (account.update @session_hash["id"], update_fields)
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
        return {:id => @session_hash["id"], :name => @session_hash["name"], :admin => @session_hash["admin"], :github => @session_hash["github"], :github_username => @session_hash["github_username"]}.to_json
    end

    account_roles_get = lambda do
        account = Account.new
        return (account.get_account_roles params[:user_id], {}).to_json
    end

    account_roles_get_by_role = lambda do
        account = Account.new
        query = {:id => params[:role_id]}
        return (account.get_account_roles params[:user_id], query).to_json
    end

    account_roles_patch_by_id = lambda do
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

    user_skillsets_get = lambda do
        issue = Issue.new
        return (issue.get_user_skillsets params[:user_id], {}).to_json
    end

    user_skillsets_get_by_skillset = lambda do
        issue = Issue.new
        query = {:id => params[:skillset_id]}
        return (issue.get_user_skillsets params[:user_id], query)[0].to_json
    end

    user_skillsets_patch = lambda do
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
        authorized?
        issue = Issue.new
        query = {:project_id => params[:project_id].to_i }
        if @session_hash
            sprints = issue.get_sprints query, @session_hash["id"] 
        else
            sprints = issue.get_sprints query, nil 
        end
        return sprints.to_json
    end

    sprint_states_get = lambda do
        authorized?
        issue = Issue.new
        query = {"sprints.project_id" => params[:project_id].to_i }
        sprint_states = issue.get_sprint_states query
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
        authorized?
        issue = Issue.new
        query = {:project_id => params[:project_id].to_i, :id => params[:id].to_i } 
        if @session_hash
            sprint = issue.get_sprints query,  @session_hash["id"]
        else
            sprint = issue.get_sprints query, nil
        end
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
                    sprint_state = issue.create_sprint_state sprint.id, 1, nil
                    log_params = {:sprint_id => sprint.id, :state_id => 1, :user_id => @session_hash["id"], :project_id => params[:project_id]}
                    if sprint && sprint_state && (issue.log_event log_params)
                        status 201
                        response = sprint_state
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
                    query = {:id => params[:project_id].to_i}
                    project = (issue.get_projects query)[0]

                    repo = Repo.new
                    github = (repo.github_client github_authorization)

                    sha = github.branch("#{project["org"]}/#{project["name"]}","master").commit.sha

                    sprint_state = issue.create_sprint_state params[:id], fields[:state_id], sha
                    log_params = {:sprint_id => sprint_state["id"], :state_id => fields[:state_id], :user_id => @session_hash["id"], :project_id => params[:project_id]}
                    if sprint_state && (issue.log_event log_params) 
                        status 201
                        response = sprint_state
                    end
                end
            end
        else
            status 401
            response[:message] = "You are not authorized to perform this action."
        end
        return response.to_json
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
                sprint = issue.get_sprints query, nil
                project_id = sprint[0][:project]["id"]

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
            sprint = issue.get_sprints query, nil
            project_id = sprint[0][:project]["id"]

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
                            log_params = {:sprint_id => sprint_state.sprint_id, :sprint_state_id =>  sprint_state.id, :user_id => @session_hash["id"], :project_id => project["id"]}
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
                                query = {:id => sprint_state.sprint_id}
                                idea = issue.get_idea query
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

  get_user_info = lambda do
    user_id = (default_to_signed params[:user_id])
    if user_id
      issue = Issue.new
      user_info = issue.get_user_info user_id
      return user_info.to_json
    end
  end

    #API
    post "/register", &register_post
    post "/forgot", &forgot_post
    post "/reset", &reset_post
    post "/login", &login_post
    post "/session/:provider", &session_provider_post
    delete "/session", &session_delete
    get "/account", &account_get
    get "/account/:user_id/skillsets", &user_skillsets_get
    get "/account/:user_id/skillsets/:skillset_id", &user_skillsets_get_by_skillset
    patch "/account/:user_id/skillsets/:skillset_id", &user_skillsets_patch 

    post "/account/connections", &connections_request_post
    get "/account/connections", &connections_get
    get "/account/connections/confirmed", &get_user_info
    patch "/account/connections/read", &user_connections_patch_read
    patch "/account/connections/confirmed", &user_connections_patch_confirmed

    get "/account/:user_id/roles", &account_roles_get
    get "/account/:user_id/roles/:role_id", &account_roles_get_by_role
    patch "/account/:user_id/roles/:role_id", &account_roles_patch_by_id

    get "/roles", &roles_get
    get "/states", &states_get
    get "/skillsets", &skillsets_get

    get "/sprints/:sprint_id/skillsets", &sprint_skillsets_get
    get "/sprints/:sprint_id/skillsets/:skillset_id", &sprint_skillsets_get_by_skillset
    patch "/sprints/:sprint_id/skillsets/:skillset_id", &sprint_skillsets_patch 

    get "/repositories", &repositories_get

    post "/projects", &projects_post
    get "/projects", &projects_get
    get "/projects/:id", &projects_get_by_id


    post "/projects/:project_id/refresh", &refresh_post
    post "/projects/:project_id/contributors", &contributors_post
    patch "/projects/:project_id/contributors/:contributor_id", &contributors_patch_by_id
    get "/projects/:project_id/contributors/:contributor_id", &contributors_get_by_id

    post "/projects/:project_id/sprints", &sprints_post
    get "/projects/:project_id/sprints", &sprints_get
    get "/projects/:project_id/sprint-states", &sprint_states_get
    get "/projects/:project_id/events", &events_get
    get "/projects/:project_id/sprints/:id", &sprints_get_by_id
    patch "/projects/:project_id/sprints/:id", &sprints_patch_by_id

    post "/contributors/:id/comments", &contributors_post_comments
    post "/contributors/:id/votes", &contributors_post_votes
    post "/contributors/:id/winner", &contributors_post_winner
    post "/contributors/:id/merge", &contributors_post_merge

    get "/aggregate-comments", &comments_get
    get "/aggregate-votes", &votes_get
    get "/aggregate-contributors", &contributors_get

    get '/unauthorized' do
        status 401
        return {:message => "Looks like we went too far?"}.to_json
    end

    #Ember
    get "*" do
        send_file File.expand_path('index.html',settings.public_folder)
    end

end

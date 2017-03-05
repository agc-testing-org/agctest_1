require_relative '../spec_helper'

describe "/projects" do
    fixtures :users
    before(:all) do
        @mysql_client = Mysql2::Client.new(
            :host => ENV['INTEGRATIONS_MYSQL_HOST'],
            :username => ENV['INTEGRATIONS_MYSQL_USERNAME'],
            :password => ENV['INTEGRATIONS_MYSQL_PASSWORD'],
            :database => "integrations_#{ENV['RACK_ENV']}"
        )
        @redis = Redis.new(:host => ENV['INTEGRATIONS_REDIS_HOST'], :port => ENV['INTEGRATIONS_REDIS_PORT'], :db => ENV['INTEGRATIONS_REDIS_DB'])
    end
    before(:each) do
        admin_password = "adam12345"
        admin_email = users(:adam_admin).email
        post "/login", { :password => admin_password, :email => admin_email }.to_json
        res = JSON.parse(last_response.body)
        @admin_w7_token = res["w7_token"]

        @user = users(:adam_confirmed).id
        email = users(:adam_confirmed).email
        post "/login", { :password => admin_password, :email => email }.to_json
        res = JSON.parse(last_response.body)
        @non_admin_w7_token = res["w7_token"]
    
        code = "123"
        access_token = "ACCESS123"

        Octokit::Client.any_instance.stub(:exchange_code_for_token) { JSON.parse({
            :access_token => access_token
        }.to_json, object_class: OpenStruct) }

        @username = "ADAM123"
        Octokit::Client.any_instance.stub(:login) { @username }
        post "/session/github", {:grant_type => "github", :auth_code => code }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
        res = JSON.parse(last_response.body)
        @non_admin_github_token = res["github_token"]

        FileUtils.rm_rf('repositories/')
        %x( mkdir "test/#{@username}")
        @uri = "test/#{@username}/git-repo-log.git"
        @uri_master = "test/ADAM123/DEMO.git"
        @sha = "b218bd1da7786b8beece26fc2e6b2fa240597969"
        %x( rm -rf #{@uri})
        %x( cp -rf test/git-repo #{@uri_master}; mv #{@uri_master}/git #{@uri_master}/.git)
        %x( cp -rf test/git-repo #{@uri}; mv #{@uri}/git #{@uri}/.git)

    end
    after(:each) do
        %x( rm -rf #{@uri})
        %x( rm -rf #{@uri_master})
        %x( rm -rf "test/#{@username}")
        %x( rm -rf repositories/*)
    end

    describe "POST /" do
        before(:each) do
            @org = "AGC_ORG" 
            @name = "NEW PROJECT"
        end
        context "non-admin" do
            before(:each) do
                post "/projects", { :name => @name, :org => @org }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                @mysql = @mysql_client.query("select * from projects").first
                @res = JSON.parse(last_response.body)
            end
            it "should not return an id" do
                expect(@res.keys).to_not include("id")
            end

        end
        context "admin" do
            context "valid fields" do
                before(:each) do
                    post "/projects", { :name => @name, :org => @org }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@admin_w7_token}"}
                    @mysql = @mysql_client.query("select * from projects").first
                    @res = JSON.parse(last_response.body)
                end
                context "project" do
                    it "should include name" do
                        expect(@mysql["name"]).to eq(@name)
                    end
                    it "should include org" do
                        expect(@mysql["org"]).to eq(@org)
                    end
                end
                it "should return project id" do
                    expect(@res["id"]).to eq(@mysql["id"])  
                end 
            end
        end
    end
    shared_examples_for "project" do
        it "should return id" do
            expect(@project["id"]).to eq(@project_result["id"])
        end
        it "should return org" do
            expect(@project["org"]).to eq(@project_result["org"])           
        end
        it "should return name" do
            expect(@project["name"]).to eq(@project_result["name"])
        end
    end
    shared_examples_for "sprint_timeline" do
        it "should return the sprint_id" do
            @timeline_result.each_with_index do |t,i|
                expect(@timeline[i]["sprint"]["id"]).to eq(t["sprint_id"])
            end
        end
        it "should return the user_id" do
            @timeline_result.each_with_index do |t,i|
                expect(@timeline[i]["user"]["id"]).to eq(t["user_id"])
            end
        end
        it "should return the state_id" do
            @timeline_result.each_with_index do |t,i|
                expect(@timeline[i]["state"]["id"]).to eq(t["state_id"])
            end
        end
        it "should return the label_id" do
            @timeline_result.each_with_index do |t,i|
                expect(@timeline[i]["label"]["id"]).to eq(t["label_id"])
            end
        end
        it "should return the after id" do
            @timeline_result.each_with_index do |t,i|
                expect(@timeline[i]["after"]).to eq(t["after"])
            end
        end
    end
    shared_examples_for "projects" do
        it "should return more than one result" do
            expect(@projects[0]["id"]).to eq(@project_results.first["id"])
        end
    end
    describe "GET /" do
        fixtures :projects
        before(:each) do
            get "/projects"
            @projects = JSON.parse(last_response.body)
            @project_results = @mysql_client.query("select * from projects")
        end
        it_behaves_like "projects"
    end 
    describe "GET /:id" do
        fixtures :users, :sprints, :labels, :states, :projects, :sprint_timelines
        before(:each) do
            project_id = projects(:demo).id
            get "/projects/#{project_id}"
            @project = JSON.parse(last_response.body)
            @project_result = @mysql_client.query("select * from projects where id = #{project_id}").first
        end
        it_behaves_like "project"
    end
    describe "POST /:id/sprints" do
        fixtures :projects, :states, :labels, :sprint_timelines
        before(:each) do
            @title = "SPRINT TITLE"
            @description = "SPRINT DESCRIPTION"
            @project_id = projects(:demo).id
            @sha = "SHA"
        end
        context "valid fields" do
            before(:each) do
                post "/projects/#{@project_id}/sprints", {:title => @title, :description => @description, :project_id => @project_id }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                @mysql = @mysql_client.query("select * from sprints").first
                @res = JSON.parse(last_response.body)
                @timeline = @mysql_client.query("select * from sprint_timelines where sprint_id = #{@res["id"]}").first
                puts @timeline.inspect
            end
            context "sprint" do
                it "should include title" do
                    expect(@mysql["title"]).to eq(@title)
                end
                it "should include description" do
                    expect(@mysql["description"]).to eq(@description)
                end
                it "should include project_id" do
                    expect(@mysql["project_id"]).to eq(@project_id)
                end
                it "should include user_id" do
                    expect(@mysql["user_id"]).to eq(@user)
                end
            end
            context "sprint_timeline" do
                it "should include sprint_id" do
                    expect(@timeline["sprint_id"]).to eq(@res["id"])
                end
                it "should include state_id" do
                    expect(@timeline["state_id"]).to eq(states(:idea).id)
                end
                it "should include label_id" do
                    expect(@timeline["label_id"]).to be nil 
                end
                it "should include after" do
                    expect(@timeline["after"]).to be nil 
                end
            end
            it "should return sprint id" do
                expect(@res["id"]).to eq(@mysql["id"])
            end
        end
    end
    shared_examples_for "sprint" do
        it "should return id" do
            expect(@sprint["id"]).to eq(@sprint_result["id"])
        end
        it "should return user_id" do
            expect(@sprint["user_id"]).to eq(@sprint_result["user_id"])
        end
        it "should return title" do
            expect(@sprint["title"]).to eq(@sprint_result["title"])
        end
        it "should return description" do
            expect(@sprint["description"]).to eq(@sprint_result["description"])
        end
        it "should return sha" do
            expect(@sprint["sha"]).to eq(@sprint_result["sha"])
        end
        it "should return winnder_id" do
            expect(@sprint["winner_id"]).to eq(@sprint_result["winner_id"])
        end 
    end
    shared_examples_for "sprints" do
        it "should return more than one result" do
            expect(@sprints[0]["id"]).to eq(@sprint_results.first["id"])
        end
    end

    shared_examples_for "sprint_states" do
        it "should return id" do
            @sprint_state_result.each_with_index do |s,i|
                expect(@sprint_state[i]["id"]).to eq(s["id"])
            end
        end
        it "should return deadline" do
            @sprint_state_result.each_with_index do |s,i|
                expect(@sprint_state[i]["deadline"]).to_not be nil
            end
        end
        it "should return state" do
            @sprint_state_result.each_with_index do |s,i|
                expect(@sprint_state[i]["state"]["id"]).to eq(s["state_id"])
            end
        end
    end

    shared_examples_for "contributors" do
        it "should return id" do
            @contributor_result.each_with_index do |c,i|
                expect(@contributors[i]["id"]).to eq(c["id"])
            end
        end
        context "when owned" do
            it "should return repo name" do
                @contributor_result.each_with_index do |c,i|
                    if @user == c["user_id"]
                        expect(@contributors[i]["repo"]).to eq(c["repo"])
                    end
                end
            end
        end
    end

    describe "GET /:id/sprints" do
        fixtures :projects, :sprints
        before(:each) do
            project_id = projects(:demo).id
            get "/projects/#{project_id}/sprints"
            res = JSON.parse(last_response.body)
            @sprint_results = @mysql_client.query("select * from sprints where project_id = #{project_id}")
            @project_result = @mysql_client.query("select * from projects where id = #{project_id}").first
            @project = res[0]["project"]
            @sprints = res
        end

        it_behaves_like "project"
        it_behaves_like "sprints"
    end

    describe "GET /:id/events" do
        fixtures :users, :sprints, :labels, :states, :projects, :sprint_timelines
        context "no filter" do
            before(:each) do
                project_id = projects(:demo).id
                get "/projects/#{project_id}/events"
                @timeline = JSON.parse(last_response.body)
                @timeline_result = @mysql_client.query("select * from sprint_timelines where project_id = #{project_id}")
            end
            it_behaves_like "sprint_timeline"
        end
        context "filter by sprint_id" do
            before(:each) do
                project_id = projects(:demo).id
                @sprint_id = sprints(:sprint_1).id
                get "/projects/#{project_id}/events?sprint_id=#{@sprint_id}"
                @timeline = JSON.parse(last_response.body)
                @timeline_result = @mysql_client.query("select * from sprint_timelines where sprint_id = #{@sprint_id}")
            end
            it "should return only sprint_1 events" do
                @timeline_result.each_with_index do |t,i|
                    expect(@timeline[i]["sprint"]["id"]).to eq(@sprint_id)
                end
            end
            it_behaves_like "sprint_timeline"
        end
    end

    describe "GET /:id/sprints/:id" do
        fixtures :projects, :sprints, :sprint_states, :states, :contributors
        before(:each) do
            sprint = sprints(:sprint_1)
            get "/projects/#{sprint.project_id}/sprints/#{sprint.id}", {}, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
            res = JSON.parse(last_response.body)
            @sprint_result = @mysql_client.query("select * from sprints where project_id = #{sprint.project_id}").first
            @project_result = @mysql_client.query("select * from projects where id = #{sprint.project_id}").first
            @sprint_state_result = @mysql_client.query("select * from sprint_states where sprint_id = #{sprint.id}")
            @contributor_result = @mysql_client.query("select * from contributors where sprint_state_id = #{sprint_states(:sprint_1_state_1).id}")
            @project = res["project"]
            @sprint = res
            @sprint_state = res["sprint_states"]
            @contributors = res["sprint_states"][0]["contributors"]
            #            puts res.inspect
        end

        it_behaves_like "project"
        it_behaves_like "sprint"
        it_behaves_like "sprint_states"
        it_behaves_like "contributors"
    end

    describe "PATCH /:id/sprints/:id" do
        fixtures :projects, :sprints, :sprint_states, :states
        before(:each) do
            body = { 
                :name=>"1", 
                :commit=>{
                    :sha=>sprint_states(:sprint_1_state_1).sha
                }
            }

            @body = JSON.parse(body.to_json, object_class: OpenStruct)
            Octokit::Client.any_instance.stub(:branch => @body)

            sprint = sprints(:sprint_1)
            patch "/projects/#{sprint.project_id}/sprints/#{sprint.id}", {:state_id => states(:idea).id }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@admin_w7_token}"}
            @res = JSON.parse(last_response.body)
            @sprint_result = @mysql_client.query("select * from sprint_states where sprint_id = #{sprint.id} ORDER BY id DESC").first 
        end

        context "sprint_state" do
            it "should create id" do
                expect(@sprint_result["id"]).to eq(@res["id"])
            end
            it "should save sprint_id" do
                expect(@sprint_result["sprint_id"]).to eq(sprints(:sprint_1).id)
            end
            it "should save state_id" do
                expect(@sprint_result["state_id"]).to eq(states(:idea).id)
            end
            it "should save sha" do
                expect(@sprint_result["sha"]).to eq(sprint_states(:sprint_1_state_1).sha)
            end
        end
    end
    describe "POST /projects/:id/refresh" do
        fixtures :projects, :sprints, :sprint_states, :contributors
        before(:each) do
            Octokit::Client.any_instance.stub(:login) { @username }
            Octokit::Client.any_instance.stub(:create_repository) { {} }

            body = {
                :name=>"1",
                :commit=>{
                    :sha=>sprint_states(:sprint_1_state_1).sha
                }
            }

            @body = JSON.parse(body.to_json, object_class: OpenStruct)
            Octokit::Client.any_instance.stub(:branch => @body)
        end
        context "valid project" do
            fixtures :users, :sprint_states, :states, :projects
            before(:each) do
                @sprint_state_id = sprint_states(:sprint_1_state_1).id
                @project = projects(:demo).id
                post "/projects/#{@project}/contributors", {:sprint_state_id => @sprint_state_id }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
                %x(cd #{@uri_master}; git checkout master; echo "changing" > newfile; git add .; git commit -m"new commit")
                @head = %x(cd #{@uri_master}; git log)
                %x(cd #{@uri}; git checkout -b "nb")
                post "/projects/#{@project}/refresh", {}, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
                @res = JSON.parse(last_response.body)
            end
            context "repo" do
                before(:each) do
                    @git = %x(cd #{@uri}; git checkout master; git log)
                end
                it "should update head" do
                    expect(@git).to eq(@head)
                end
            end
        end
    end
    describe "POST /projects/:id/contributors" do
        fixtures :projects, :sprints, :sprint_states, :contributors
        before(:each) do
            Octokit::Client.any_instance.stub(:login) { @username }
            Octokit::Client.any_instance.stub(:create_repository) { {} }

            body = {
                :name=>"1",
                :commit=>{
                    :sha=>sprint_states(:sprint_1_state_1).sha
                }
            }

            @body = JSON.parse(body.to_json, object_class: OpenStruct)
            Octokit::Client.any_instance.stub(:branch => @body)
        end
        context "valid sprint_state_id" do
            fixtures :users, :sprint_states, :states, :projects
            before(:each) do
                @sprint_state_id = sprint_states(:sprint_1_state_1).id
                @project = projects(:demo).id
                post "/projects/#{@project}/contributors", {:sprint_state_id => @sprint_state_id }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
                @res = JSON.parse(last_response.body)
                @sql = @mysql_client.query("select * from contributors ORDER BY ID DESC").first
            end
            context "contributor" do
                it "should include repo name" do
                    expect(@sql["repo"]).to_not be nil
                end
                it "should include user_id" do
                    expect(@sql["user_id"]).to eq(users(:adam_confirmed).id)
                end
                it "should include sprint_state_id" do
                    expect(@sql["sprint_state_id"]).to eq(@sprint_state_id)
                end
            end
            it "should return contributor id" do
                expect(@res["id"]).to eq(@sql["id"])
            end
            context "repo" do
                before(:each) do
                    @git = %x(cd #{@uri}; git branch)
                end
                it "should create master branch" do
                    expect(@git).to include("master")
                end
                it "should create sprint_state branch" do
                    expect(@git).to include(@sprint_state_id.to_s)
                end
            end
        end 
        context "invalid sprint_state_id" do
            fixtures :users, :projects
            before(:each) do
                @project = projects(:demo).id
                @sprint_state_id = 99
                post "/projects/#{@project}/contributors", {:sprint_state_id => @sprint_state_id }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
                @res = JSON.parse(last_response.body)
            end
            it "should return nil" do
                expect(@res["message"]).to_not be nil
            end
        end
        context "sprint_state_id with contributor = false" do
            fixtures :users, :sprint_states, :states,  :projects
            before(:each) do
                @sprint_state_id = sprint_states(:sprint_1_no_contributors).id
                @project = projects(:demo).id
                post "/projects/#{@project}/contributors", {:sprint_state_id => @sprint_state_id }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
                @res = JSON.parse(last_response.body)
            end
            it "should return not return contributor id" do
                expect(@res.keys).to_not include("id")
            end
            it "should return error message" do
                expect(@res["message"]).to eq("We are not accepting contributions at this time")
            end
        end
    end
    describe "GET /projects/:id/contributors/:contributor_id" do
        fixtures :projects, :sprints, :sprint_states, :contributors
        before(:each) do
            @project = projects(:demo).id
        end
        context "valid contributor" do
            before(:each) do
                get "/projects/#{@project}/contributors/#{contributors(:adam_confirmed_1).id}", {}, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                @sql = @mysql_client.query("select * from contributors ORDER BY ID DESC").first
                @res = JSON.parse(last_response.body)
            end
            it "should return contributor id" do
                expect(@res["id"]).to eq(@sql["id"])
            end
        end

    end
    describe "PATCH /projects/:id/contributors/:contributor_id" do
        fixtures :projects, :sprints, :sprint_states, :contributors
        before(:each) do
            Octokit::Client.any_instance.stub(:login) { @username }
            Octokit::Client.any_instance.stub(:create_repository) { {} }

            body = {
                :name=>"1",
                :commit=>{
                    :sha=>sprint_states(:sprint_1_state_1).sha
                }
            }

            @body = JSON.parse(body.to_json, object_class: OpenStruct)
            Octokit::Client.any_instance.stub(:branch => @body)
        end
        context "valid contributor" do
            fixtures :users, :sprint_states, :projects, :contributors
            before(:each) do
                @sprint_state_id = contributors(:adam_confirmed_1).sprint_state_id
                @project = projects(:demo).id

                %x( cd #{@uri}; git checkout -b #{@sprint_state_id}; git add .; git commit -m"new branch"; git branch)
                patch "/projects/#{@project}/contributors/#{contributors(:adam_confirmed_1).id}", {}, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
                @res = JSON.parse(last_response.body)
                @sql = @mysql_client.query("select * from contributors ORDER BY ID DESC").first
            end
            context "contributor" do
                it "should include commit" do
                    expect(@sql["commit"]).to eq(@sha)
                end
                it "should include commit_success" do
                    expect(@sql["commit_success"]).to eq(1) 
                end
            end
            it "should return contributor id" do
                expect(@res["id"]).to eq(@sql["id"])
            end
        end
        context "invalid contributor" do
            fixtures :users, :projects
            before(:each) do
                @project = projects(:demo).id
                @sprint_state_id = 99
                patch "/projects/#{@project}/contributors/33", {}, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
                @res = JSON.parse(last_response.body)
            end
            it "should return nil" do
                expect(@res["message"]).to_not be nil
            end
        end
    end
    describe "POST /contributors/:id/comments" do
        fixtures :projects, :sprints, :sprint_states, :contributors
        before(:each) do
            @sprint_state_id = contributors(:adam_confirmed_1).sprint_state_id
            @contributor_id = contributors(:adam_confirmed_1).id
            @project = projects(:demo).id
        end
        context "valid comment" do
            before(:each) do
                @text = "AB"
                post "/contributors/#{@contributor_id}/comments", {:text => @text, :sprint_state_id => @sprint_state_id}.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
                @res = JSON.parse(last_response.body)
                @mysql = @mysql_client.query("select * from comments").first
            end
            it "should return comment id" do
                expect(@res["id"]).to eq(1)
            end
            context "comment" do
                it "should save text" do
                    expect(@mysql["text"]).to eq(@text)
                end
                it "should save contributor_id" do
                    expect(@mysql["contributor_id"]).to eq(@contributor_id)
                end
            end
        end
        context "invalid comment" do
            it "should return error message" do
                post "/contributors/#{@contributor_id}/comments", {:text => "A", :sprint_state_id => @sprint_state_id}.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
                res = JSON.parse(last_response.body)
                expect(res["message"]).to eq("Please enter a more detailed comment")
            end
        end
    end
    describe "POST /contributors/:id/votes" do
        fixtures :projects, :sprints, :sprint_states, :contributors
        before(:each) do
            @sprint_state_id = contributors(:adam_confirmed_1).sprint_state_id
            @contributor_id = contributors(:adam_confirmed_1).id
            @project = projects(:demo).id
            post "/contributors/#{@contributor_id}/votes", {:sprint_state_id => @sprint_state_id}.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
            @res = JSON.parse(last_response.body)
            @mysql = @mysql_client.query("select * from votes").first
        end
        it "should return vote id" do
            expect(@res["id"]).to eq(1)
        end
        it "should return created status true for a new vote" do
            expect(@res["created"]).to be true
        end
        context "downvote" do
            it "should return created status false for a repeat vote" do
                post "/contributors/#{@contributor_id}/votes", {:sprint_state_id => @sprint_state_id}.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
                res = JSON.parse(last_response.body)
                expect(res["created"]).to be false
            end
        end
        context "vote" do
            it "should save contributor_id" do
                expect(@mysql["contributor_id"]).to eq(@contributor_id)
            end
        end
        it "should only allow one vote per sprint" do
            contributor_id = contributors(:adam_admin_1).id
            post "/contributors/#{contributor_id}/votes", {:sprint_state_id => @sprint_state_id}.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
            mysql = @mysql_client.query("select * from votes")
            expect(mysql.count).to eq(1)
            expect(mysql.first["contributor_id"]).to eq(contributor_id)
        end
    end
    describe "POST /contributors/:id/winner" do
        fixtures :users, :projects, :sprints, :sprint_states, :contributors
        before(:each) do
            @sprint_state_id = contributors(:adam_confirmed_1).sprint_state_id
            @contributor_id = contributors(:adam_confirmed_1).id
            @project = projects(:demo).id
            @pull_id = 222
            body = {
                :number => @pull_id,
                :name=>"1",
                :commit=>{
                    :sha=>sprint_states(:sprint_1_state_1).sha
                }
            }

            @body = JSON.parse(body.to_json, object_class: OpenStruct)
            Octokit::Client.any_instance.stub(:create_pull_request => @body)

            post "/contributors/#{@contributor_id}/winner", {:project_id => @project, :sprint_state_id => @sprint_state_id}.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
            @res = JSON.parse(last_response.body)
            @mysql = @mysql_client.query("select * from sprint_states").first
            @timeline = @mysql_client.query("select * from sprint_timelines").first
        end
        context "admin" do
            it "should return sprint_state id" do
                expect(@res["id"]).to eq(@sprint_state_id)
            end
            context "sprint_state" do
                it "should save contributor_id (winner)" do
                    expect(@mysql["contributor_id"]).to eq(@contributor_id)
                end
                it "should save arbiter (judge)" do
                    expect(@mysql["arbiter_id"]).to eq(users(:adam_admin).id)
                end
                it "should save pull request" do
                    expect(@mysql["pull_request"]).to eq(@pull_id)
                end
            end
            context "sprint_timeline" do
                it "should save sprint_state_id" do
                    expect(@timeline["sprint_state_id"]).to eq(@sprint_state_id)
                end
            end
        end
    end
    describe "POST /contributors/:id/merge" do
        fixtures :users, :projects, :sprints, :sprint_states, :contributors
        before(:each) do
            @sprint_state_id = contributors(:adam_confirmed_1).sprint_state_id
            @contributor_id = contributors(:adam_confirmed_1).id
            @project = projects(:demo).id
            @pull_id = 222
            body = {
                :number => @pull_id,
                :name=>"1",
                :commit=>{
                    :sha=>sprint_states(:sprint_1_state_1).sha
                }
            }

            @body = JSON.parse(body.to_json, object_class: OpenStruct)
            Octokit::Client.any_instance.stub(:create_pull_request => @body)
            Octokit::Client.any_instance.stub(:merge_pull_request => @body)
            post "/contributors/#{@contributor_id}/winner", {:project_id => @project, :sprint_state_id => @sprint_state_id}.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
            post "/contributors/#{@contributor_id}/merge", {:project_id => @project, :sprint_state_id => @sprint_state_id}.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
            @res = JSON.parse(last_response.body)
            @mysql = @mysql_client.query("select * from sprint_states").first
        end
        context "admin" do
            it "should return sprint_state id" do
                expect(@res["id"]).to eq(@sprint_state_id)
            end
            context "sprint_state" do
                it "should update merged" do
                    expect(@mysql["merged"]).to eq(1) 
                end
            end
        end
    end
    describe "GET /aggregates/aggregate-comments" do
        fixtures :users, :projects, :sprints, :sprint_states, :contributors, :comments
        context "user created" do
            before(:each) do
                get "/aggregates/aggregate-comments?user_id=#{users(:adam_confirmed).id}",{}, {}
                @res = JSON.parse(last_response.body)
            end
            it "should return comments based on filter" do
                expect(@res[0]["id"]).to eq(comments(:adam_confirmed_1).id)
            end
        end
        context "user received" do
            before(:each) do
                get "/aggregates/aggregate-comments?contributor_id=#{users(:adam_confirmed).id}",{}, {}
                @res = JSON.parse(last_response.body)
            end
            it "should return comments based on filter" do
                expect(@res[0]["id"]).to eq(comments(:adam_admin_1).id)
            end
        end

    end
    describe "GET /aggregates/aggregate-votes" do
        fixtures :users, :projects, :sprints, :sprint_states, :contributors, :votes
        context "user created" do
            before(:each) do
                get "/aggregates/aggregate-votes?user_id=#{users(:adam_confirmed).id}",{}, {}
                @res = JSON.parse(last_response.body)
            end
            it "should return votes based on filter" do
                expect(@res[0]["id"]).to eq(votes(:adam_confirmed_1).id)
            end
        end
        context "user received" do
            before(:each) do
                get "/aggregates/aggregate-votes?contributor_id=#{users(:adam_confirmed).id}",{}, {}
                @res = JSON.parse(last_response.body)
            end
            it "should return votes based on filter" do
                expect(@res[0]["id"]).to eq(votes(:adam_admin_1).id)
            end
        end

    end
    describe "GET /aggregates/aggregate-contributors", :focus => true do
        fixtures :users, :projects, :sprints, :sprint_states, :contributors
        context "user created" do
            before(:each) do
                get "/aggregates/aggregate-contributors?user_id=#{users(:adam_confirmed).id}",{}, {}
                @res = JSON.parse(last_response.body)
            end
            it "should return contributions based on filter" do
                expect(@res[0]["id"]).to eq(contributors(:adam_confirmed_1).id)
            end
        end
        context "user received" do
            before(:each) do
                @mysql_client.query("update sprint_states set contributor_id = #{contributors(:adam_confirmed_1).id}")
                get "/aggregates/aggregate-contributors?user_id=#{users(:adam_confirmed).id}&contributor_id=#{users(:adam_confirmed).id}",{}, {}
                @res = JSON.parse(last_response.body)
            end
            it "should return contributions based on filter" do
                expect(@res[0]["id"]).to eq(contributors(:adam_confirmed_1).id)
            end
        end
    end
end

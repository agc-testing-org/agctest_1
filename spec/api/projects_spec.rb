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
                puts last_response.body.inspect
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
        fixtures :projects
        before(:each) do 
            project_id = projects(:demo).id
            get "/projects/#{project_id}"
            @project = JSON.parse(last_response.body)
            @project_result = @mysql_client.query("select * from projects where id = #{project_id}").first
        end
        it_behaves_like "project"
    end
    describe "POST /:id/sprints" do
        fixtures :projects
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
    describe "GET /:id/sprints/:id" do
        fixtures :projects, :sprints
        before(:each) do
            sprint = sprints(:sprint_1)
            get "/projects/#{sprint.project_id}/sprints/#{sprint.id}"
            res = JSON.parse(last_response.body)
            @sprint_result = @mysql_client.query("select * from sprints where project_id = #{sprint.project_id}").first
            @project_result = @mysql_client.query("select * from projects where id = #{sprint.project_id}").first
            @project = res["project"]
            @sprint = res
        end

        it_behaves_like "project"
        it_behaves_like "sprint"
    end
end

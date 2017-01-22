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
    shared_examples_for "project" do |p,mp|
        it "should return id" do
            expect(p["id"]).to eq(mp["id"])
        end
        it "should return org" do
            expect(p["org"]).to eq(mp["org"])           
        end
        it "should return name" do
            expect(p["name"]).to eq(mp["name"])
        end
    end
    describe "GET /" do
        fixtures :projects
        before(:each) do
            get "/projects"
            @res = JSON.parse(last_response.body)
            @projects = @mysql_client.query("select * from projects")
            @res.each_with_index do |p,i|
                it_behaves_like "project", p, @projects[i]
            end
        end
    end 
    describe "GET /:id" do
        fixtures :projects
        before(:each) do 
            project_id = projects(:demo).id
            get "/projects/#{project_id}"
            res = JSON.parse(last_response.body)
            project = @mysql_client.query("select * from projects where id = #{project_id}").first
            it_behaves_like "project", res, project
        end
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
end

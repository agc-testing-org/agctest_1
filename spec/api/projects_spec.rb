require_relative '../spec_helper'
require_relative '../api_spec_helper'

describe "/projects" do

    fixtures :users

    shared_examples_for "project" do
        context "response should match projects table record" do
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
    end

    shared_examples_for "projects" do
        it "should return more than one result" do
            expect(@projects.length).to be > 0
        end

        if @project_results
            @project_results.each_with_index do |p,i|
                @project_result = p
                @project = @projects[i]
                it_should_behave_like "project"
            end
        end
    end

    describe "POST /" do
        before(:each) do
            @org = "AGC_ORG" 
            @name = "NEW PROJECT"
        end
        context "non-admin" do
            before(:each) do
                post "/projects", { :name => @name, :org => @org }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                @mysql = @mysql_client.query("select * from projects")
            end
            context "response" do
                it_should_behave_like "unauthorized"
            end
            context "projects table" do
                it "should not include an id" do
                    expect(@mysql.count).to eq 0
                end 
            end 
        end
        context "admin" do
            context "valid fields" do
                before(:each) do
                    post "/projects", { :name => @name, :org => @org }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@admin_w7_token}"}
                    @project_result = @mysql_client.query("select * from projects").first
                    @project = JSON.parse(last_response.body)
                end
                it "response should match params" do
                    expect(@project["name"]).to eq(@name)
                end
                it_should_behave_like "project"
            end
        end
    end

    describe "GET /" do
        fixtures :projects
        before(:each) do
            get "/projects"
            @projects = JSON.parse(last_response.body)
            @project_results = @mysql_client.query("select * from projects")
        end
        it_should_behave_like "projects"
    end 

    describe "GET /:id" do
        fixtures :users, :sprints, :labels, :states, :projects, :sprint_timelines
        before(:each) do
            project_id = projects(:demo).id
            get "/projects/#{project_id}"
            @project = JSON.parse(last_response.body)
            @project_result = @mysql_client.query("select * from projects where id = #{project_id}").first
        end
        it_should_behave_like "project"
    end
end

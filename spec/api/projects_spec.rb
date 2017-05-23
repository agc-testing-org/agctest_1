require 'spec_helper'
require 'api_spec_helper'

describe "/projects" do

    fixtures :users

    shared_examples_for "projects" do
        it "should return id" do
            @project_results.each_with_index do |project_result,i| 
                expect(@projects[i]["id"]).to eq(project_result["id"])
            end
        end
        it "should return org" do
            @project_results.each_with_index do |project_result,i|
                expect(@projects[i]["org"]).to eq(project_result["org"])
            end
        end
        it "should return name" do
            @project_results.each_with_index do |project_result,i|
                expect(@projects[i]["name"]).to eq(project_result["name"])
            end
        end
    end

    shared_examples_for "sprint_timelines" do
        it "should return the sprint_id" do
            @timeline_result.each_with_index do |t,i|
                expect(@timeline[i]["sprint"]["id"]).to eq(t["sprint_id"])
            end
        end
        it "should return the user_id" do
            @timeline_result.each_with_index do |t,i|
                expect(@timeline[i]["user_id"]).to eq(t["user_id"])
            end
        end
        it "should return the state_id" do
            @timeline_result.each_with_index do |t,i|
                expect(@timeline[i]["state_id"]).to eq(t["state_id"])
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
                    @project_results = @mysql_client.query("select * from projects")
                    @projects = [JSON.parse(last_response.body)]
                end
                it "response should match params" do
                    expect(@projects[0]["name"]).to eq(@name)
                end
                it_should_behave_like "projects"
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
            @projects = [JSON.parse(last_response.body)]
            @project_results = @mysql_client.query("select * from projects where id = #{project_id}")
        end
        it_should_behave_like "projects"
    end


    describe "GET /:id/events" do
        fixtures :sprints, :labels, :states, :projects, :sprint_timelines
        context "no filter" do
            before(:each) do
                project_id = projects(:demo).id
                get "/projects/#{project_id}/events"
                @timeline = JSON.parse(last_response.body)
                @timeline_result = @mysql_client.query("select * from sprint_timelines where project_id = #{project_id}")
            end
            it_behaves_like "sprint_timelines"
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
            it_behaves_like "sprint_timelines"
        end
    end

    describe "POST /:id/refresh" do
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

    describe "POST /:id/contributors" do
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

    describe "GET /:id/contributors/:contributor_id" do
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

    describe "PATCH /:id/contributors/:contributor_id" do
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

end

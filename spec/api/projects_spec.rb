require 'spec_helper'
require 'api_helper'

describe "/projects" do

    fixtures :users, :seats

    before(:all) do
        @CREATE_TOKENS=true
        destroy_repo
    end

    before(:each) do
        prepare_repo
    end 

    after(:each) do
        destroy_repo
    end

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
        it "should return user_id" do
            @project_results.each_with_index do |project_result,i|
                expect(@projects[i]["user_id"]).to eq(project_result["user_id"])
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
                it_should_behave_like "unauthorized_admin"
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
                it_should_behave_like "created"
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
        it_should_behave_like "ok"
    end 

    describe "GET /:id" do
        fixtures :sprints, :states, :projects, :sprint_timelines
        before(:each) do
            project_id = projects(:demo).id
            get "/projects/#{project_id}"
            @projects = [JSON.parse(last_response.body)]
            @project_results = @mysql_client.query("select * from projects where id = #{project_id}")
        end
        it_should_behave_like "projects"
        it_should_behave_like "ok"
    end

    describe "POST /:id/refresh" do
        fixtures :projects, :sprints, :sprint_states, :contributors
        before(:each) do
            skip "We'll use this later with a bit of refactoring"
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
            fixtures :sprint_states, :states, :projects
            before(:each) do
                @sprint_state_id = sprint_states(:sprint_1_state_1).id
                @project = projects(:demo).id
                post "/projects/#{@project}/contributors", {:sprint_state_id => @sprint_state_id }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                %x(cd #{@uri_master}; git checkout master; echo "changing" > newfile; git add .; git commit -m"new commit")
                @head = %x(cd #{@uri_master}; git log)
                %x(cd #{@uri}; git checkout -b "nb")
                post "/projects/#{@project}/refresh", {}, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                @res = JSON.parse(last_response.body)
            end
            context "repo" do
                before(:each) do
                    @git = %x(cd #{@uri}; git checkout master; git log)
                end
                it "should update head", :focus => true do
                    expect(@git).to eq(@head)
                end
            end
        end
    end

    shared_examples_for "contributors_post" do
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
                @git = %x(cd "test/#{@username}/#{@mysql_client.query("select * from contributors").first["repo"]}"; git branch)
            end
            it "should create master branch" do
                expect(@git).to include("master")
            end
            it "should create sprint_state branch" do
                expect(@git).to include(@sprint_state_id.to_s)
            end
        end
    end

    describe "POST /:id/contributors" do
        fixtures :projects, :sprints, :sprint_states
        before(:each) do
            Octokit::Client.any_instance.stub(:login) { @username }
            Octokit::Client.any_instance.stub(:create_repository) { %x( mkdir "test/#{@username}/#{@mysql_client.query("select * from contributors").first["repo"]}"; cd "test/#{@username}/#{@mysql_client.query("select * from contributors").first["repo"]}"; git init --bare)}

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
            fixtures :sprint_states, :states, :projects
            before(:each) do
                @sprint_state_id = sprint_states(:sprint_1_state_1).id
                @project = projects(:demo).id
                post "/projects/#{@project}/contributors", {:sprint_state_id => @sprint_state_id }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                @res = JSON.parse(last_response.body)
                @sql = @mysql_client.query("select * from contributors ORDER BY ID DESC").first
            end
            it_behaves_like "contributors_post"
        end
        context "same sprint, different state" do
            fixtures :sprint_states, :states, :projects, :contributors
            before(:each) do
                @sprint_state_id = sprint_states(:sprint_1_state_2).id
                @project = projects(:demo).id
                %x( mkdir "test/#{@username}/#{@mysql_client.query("select * from contributors where sprint_state_id = #{sprint_states(:sprint_1_state_1).id}").first["repo"]}"; cd "test/#{@username}/#{@mysql_client.query("select * from contributors where sprint_state_id = #{sprint_states(:sprint_1_state_1).id}").first["repo"]}"; git init --bare)
                post "/projects/#{@project}/contributors", {:sprint_state_id => @sprint_state_id }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                @res = JSON.parse(last_response.body)
                @sql = @mysql_client.query("select * from contributors where sprint_state_id = #{@sprint_state_id} ORDER BY ID DESC").first
            end
            it "should use the same repo" do
                expect(@sql["repo"]).to eq(contributors(:adam_confirmed_1).repo)
            end
            it_behaves_like "contributors_post"
        end
        context "invalid sprint_state_id" do
            fixtures :projects
            before(:each) do
                @project = projects(:demo).id
                @sprint_state_id = 99
                post "/projects/#{@project}/contributors", {:sprint_state_id => @sprint_state_id }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
            end
            it_behaves_like "not_found"
        end
        context "sprint_state_id with contributor = false" do
            fixtures :sprint_states, :states,  :projects
            before(:each) do
                @sprint_state_id = sprint_states(:sprint_1_no_contributors).id
                @project = projects(:demo).id
                post "/projects/#{@project}/contributors", {:sprint_state_id => @sprint_state_id }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                @res = JSON.parse(last_response.body)
            end
            it_behaves_like "error", "unable to join this phase"
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
                @sql = @mysql_client.query("select * from contributors where user_id = #{contributors(:adam_confirmed_1).user_id} ORDER BY ID DESC").first
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
            fixtures :sprint_states, :projects, :contributors
            before(:each) do
                @sprint_state_id = contributors(:adam_confirmed_1).sprint_state_id
                @project = projects(:demo).id

                %x( cd #{@uri}; git checkout -b #{@sprint_state_id}; git add .; git commit -m"new branch"; git branch)
                patch "/projects/#{@project}/contributors/#{contributors(:adam_confirmed_1).id}", {}, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                @res = JSON.parse(last_response.body)
                @sql = @mysql_client.query("select * from contributors where user_id = #{contributors(:adam_confirmed_1).user_id} ORDER BY ID DESC").first
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
            fixtures :projects
            before(:each) do
                @project = projects(:demo).id
                @sprint_state_id = 99
                patch "/projects/#{@project}/contributors/33", {}, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                @res = JSON.parse(last_response.body)
            end
            it_behaves_like "not_found"
        end
    end
end

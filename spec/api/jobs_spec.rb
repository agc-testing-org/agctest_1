require 'spec_helper'
require 'api_helper'

describe "/jobs" do

    fixtures :users, :projects, :seats, :roles
    before(:all) do
        @CREATE_TOKENS=true
    end 

    shared_examples_for "jobs" do
        it "should return id" do
            expect(@job_results.count).to be > 0
            @job_results.each_with_index do |job_result,i|
                expect(@jobs[i]["id"]).to eq(job_result["id"])
            end
        end
        it "should return user_id" do
            @job_results.each_with_index do |job_result,i|
                expect(decrypt(@jobs[i]["user_id"]).to_i).to eq(job_result["user_id"])
            end
        end
        it "should return title" do
            @job_results.each_with_index do |job_result,i|
                expect(@jobs[i]["title"]).to eq(job_result["title"])
            end
        end
        it "should return link" do
            @job_results.each_with_index do |job_result,i|
                expect(@jobs[i]["link"]).to eq(job_result["link"])
            end
        end
        it "should return team_id" do
            @job_results.each_with_index do |job_result,i|
                expect(@jobs[i]["team_id"]).to eq(job_result["team_id"])
            end
        end
        it "should return role_id" do
            @job_results.each_with_index do |job_result,i|
                expect(@jobs[i]["role_id"]).to eq(job_result["role_id"])
            end
        end
        it "should return role (as id)" do
            if @include_role
                @job_results.each_with_index do |job_result,i|
                    expect(@jobs[i]["role"]).to eq(job_result["role_id"])
                end
            end
        end
        it "should return zip" do
            @job_results.each_with_index do |job_result,i|
                expect(@jobs[i]["zip"]).to eq(job_result["zip"])
            end
        end
        it "should return company" do
            @job_results.each_with_index do |job_result,i|
                expect(@jobs[i]["company"]).to eq(job_result["company"])
            end
        end
        it "should return sprint_id" do
            @job_results.each_with_index do |job_result,i|
                expect(@jobs[i]["sprint_id"]).to eq(job_result["sprint_id"])
                if job_result["sprint_id"] && !@hide_sprints
                    job_results_sprints = @mysql_client.query("select sprints.*, IF(sprints.id = #{(job_result["sprint_id"] || "NULL")}, 1, 0) as selected from sprints where sprints.job_id = #{job_result["id"]} ORDER BY selected DESC, id DESC")
                    jobs_sprints = @jobs[i]["sprints"]
                    expect(job_results_sprints.count).to be > 0
                    job_results_sprints.each_with_index do |job_result_sprint,i|
                        expect(jobs_sprints[i]["id"]).to eq(job_result_sprint["id"])
                    end   
                    job_results_sprints.each_with_index do |job_result_sprint,i|
                        expect(jobs_sprints[i]["project"]).to eq(job_result_sprint["project_id"])
                    end  
                end
            end
        end
    end

    describe "POST /" do
        fixtures :teams
        before(:each) do
            @title = "JOB TITLE"
            @link = "https://wired7.com/12345"
            @team_id = teams(:ateam).id
            @role_id = roles(:development).id
            @zip = "94105"
        end
        context "not on team" do
            before(:each) do
                post "jobs", {:title => @title, :role_id => @role_id, :team_id => @team_id, :link => @link, :zip => @zip }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
            end
            it_behaves_like "unauthorized"
        end
        context "on team" do
            fixtures :user_teams, :notifications
            before(:each) do
                @team_id = user_teams(:adam_confirmed).team_id
            end
            context "valid" do
                fixtures :user_profiles, :user_positions
                before(:each) do
                    post "jobs", {:title => @title, :team_id => @team_id, :role_id => @role_id, :zip => @zip, :link => @link }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                    @job_results = @mysql_client.query("select * from jobs")
                    @jobs = [JSON.parse(last_response.body)]
                    @timeline = @mysql_client.query("select * from sprint_timelines").first
                end
                it_behaves_like "jobs"
                it_behaves_like "created"
                context "sprint_timeline" do
                    it "should include job_id" do
                        expect(@timeline["job_id"]).to eq(@jobs[0]["id"])
                    end
                    it "should include notification id = job" do
                        expect(@timeline["notification_id"]).to eq(notifications(:job).id)
                    end
                end
            end
            context "invalid" do
                context "title too short" do
                    before(:each) do
                        post "jobs", {:title => "a"*4, :team_id => @team_id, :role_id => @role_id, :zip => @zip, :link => @link }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                    end
                    it_behaves_like "error", "title must be 5-100 characters"
                end
                context "title too long" do
                    before(:each) do
                        post "jobs", {:title => "a"*101, :team_id => @team_id, :role_id => @role_id, :zip => @zip, :link => @link }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                    end
                    it_behaves_like "error", "title must be 5-100 characters"
                end
                context "invalid link" do
                    before(:each) do
                        post "jobs", {:title => @title, :team_id => @team_id, :role_id => @role_id, :zip => @zip, :link => "www.wired7.com/12345" }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"} 
                    end
                    it_behaves_like "error", "a full link (http or https is required)"
                end
                context "invalid zip" do
                    before(:each) do
                        post "jobs", {:title => @title, :team_id => @team_id, :role_id => @role_id, :zip => 111, :link => @link }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                    end
                    it_behaves_like "error", "a valid zip code is required"
                end
                context "no linkedin data" do
                    before(:each) do
                        post "jobs", {:title => @title, :team_id => @team_id, :role_id => @role_id, :zip => @zip, :link => @link }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                    end
                    it_behaves_like "error", "you must connect linkedin to post a job"
                end
            end
        end
    end

    describe "GET /" do
        fixtures :jobs, :teams, :sprints
        before(:each) do
            @include_role = true
        end
        context "no filter" do
            before(:each) do
                get "/jobs"
                @jobs = JSON.parse(last_response.body)
                @job_results = @mysql_client.query("select jobs.*, jobs.role_id as role, users.first_name as user_first_name,teams.name as team_name from jobs INNER JOIN users ON users.id = jobs.user_id INNER JOIN teams ON jobs.team_id = teams.id ORDER BY id DESC")
            end
            it_behaves_like "jobs"
            it_behaves_like "ok"
        end
        context "filter by id" do
            before(:each) do
                get "/jobs?id=#{jobs(:developer).id}"
                @jobs = JSON.parse(last_response.body)
                @job_results = @mysql_client.query("select jobs.*, jobs.role_id as role, users.first_name as user_first_name,teams.name as team_name from jobs INNER JOIN users ON users.id = jobs.user_id INNER JOIN teams ON jobs.team_id = teams.id where jobs.id = #{jobs(:developer).id} ORDER BY id DESC")
            end
            it_behaves_like "jobs"
            it_behaves_like "ok"
        end
    end

    describe "GET /:id" do
        fixtures :jobs, :teams, :sprints
        before(:each) do
            job = jobs(:developer)
            get "/jobs/#{job.id}"
            @include_role = true
            @jobs = [JSON.parse(last_response.body)]
            @job_results = @mysql_client.query("select jobs.*, jobs.role_id as role, users.first_name as user_first_name,teams.name as team_name from jobs INNER JOIN users ON users.id = jobs.user_id INNER JOIN teams ON jobs.team_id = teams.id where jobs.id = #{job.id} ORDER BY id DESC")
        end
        it_behaves_like "jobs"
        it_behaves_like "ok"
    end

    describe "PATCH /:id" do
        fixtures :teams, :sprints, :jobs, :notifications, :states
        before(:each) do
            @title = "JOB TITLE"        
            @sprint_id = sprints(:sprint_2).id
            @team_id = teams(:ateam).id          
            @job = jobs(:product_manager).id
            @hide_sprints = true
        end                                                             
        context "not on team" do
            before(:each) do                    
                patch "jobs/#{@job}", {:team_id => @team_id, :sprint_id => @sprint_id }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
            end                                                                 
            it_behaves_like "unauthorized"                  
        end                                                         
        context "on team" do            
            fixtures :user_teams, :sprint_states, :notifications        
            before(:each) do
                body = {
                    :name=>"1",
                    :commit=>{
                        :sha=>sprint_states(:sprint_1_state_1).sha
                    }
                }

                @body = JSON.parse(body.to_json, object_class: OpenStruct)
                Octokit::Client.any_instance.stub(:branch => @body)
                @team_id = user_teams(:adam_confirmed).team_id        
                patch "jobs/#{@job}", {:team_id => @team_id, :sprint_id => @sprint_id }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                @jobs = [JSON.parse(last_response.body)]
                @job_results = @mysql_client.query("select jobs.*, users.first_name as user_first_name,teams.name as team_name from jobs INNER JOIN users ON users.id = jobs.user_id INNER JOIN teams ON jobs.team_id = teams.id where jobs.id = #{@job} ORDER BY id DESC")
            end
            it_behaves_like "jobs"
            it_behaves_like "ok"
            it "should set sprint_state to requirements design" do
                expect(@mysql_client.query("select * from sprint_timelines").first["state_id"]).to eq(states(:requirements_design).id)
            end
        end
        context "on a team but not correct team" do
            fixtures :user_teams, :notifications
            before(:each) do
                @team_id = teams(:adam_admin_team).id
                patch "jobs/#{@job}", {:team_id => @team_id, :sprint_id => @sprint_id }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
            end
            it_behaves_like "not_found"
        end
    end
end

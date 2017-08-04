require 'spec_helper'
require 'api_helper'

describe "/jobs" do

    fixtures :users, :projects, :seats
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
    end

    describe "POST /" do
        fixtures :teams
        before(:each) do
            @title = "JOB TITLE"
            @link = "wired7.com/12345"
            @team_id = teams(:ateam).id
        end
        context "not on team" do
            before(:each) do
                post "jobs", {:title => @title, :team_id => @team_id, :link => @link }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
            end
            it_behaves_like "unauthorized"
        end
        context "on team" do
            fixtures :user_teams, :notifications
            before(:each) do
                @team_id = user_teams(:adam_confirmed).team_id
            end
            context "valid" do
                before(:each) do
                    post "jobs", {:title => @title, :team_id => @team_id, :link => @link }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
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
                        post "jobs", {:title => "a"*4, :team_id => @team_id, :link => @link }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                    end
                    it_behaves_like "error", "title must be 5-100 characters"
                end
                context "title too long" do
                    before(:each) do
                        post "jobs", {:title => "a"*101, :team_id => @team_id, :link => @link }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                    end
                    it_behaves_like "error", "title must be 5-100 characters"
                end
            end
        end
    end

    describe "GET /", :focus => true do
        fixtures :jobs, :teams, :sprints
        before(:each) do
            get "/jobs"
            @jobs = JSON.parse(last_response.body)
            @job_results = @mysql_client.query("select jobs.*, users.first_name as user_first_name,teams.name as team_name from jobs INNER JOIN users ON users.id = jobs.user_id INNER JOIN teams ON jobs.team_id = teams.id ORDER BY id DESC")
        end
        it_behaves_like "jobs"
        it_behaves_like "ok"
    end

    describe "GET /:id" do
        fixtures :jobs, :job_states
        before(:each) do
            job = jobs(:job_1)
            get "/jobs/#{job.id}", {}, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
            @jobs = [JSON.parse(last_response.body)]
            @job_results = @mysql_client.query("select * from jobs where id = #{job.id}")
        end
        it_behaves_like "jobs"
        it_behaves_like "ok"
    end
end

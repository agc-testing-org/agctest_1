require_relative '../spec_helper'
require_relative '../api_spec_helper'

describe "/sprints" do

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
            expect(@sprints.length).to be > 0
        end

        if @sprint_results
            @sprint_results.each_with_index do |s,i|
                @sprint_result = s
                @sprint = @sprints[i]
                it_should_behave_like "sprint"
            end
        end
    end

    describe "POST /" do
        fixtures :projects, :states
        before(:each) do
            @title = "SPRINT TITLE"
            @description = "SPRINT DESCRIPTION"
            @project_id = projects(:demo).id
            @sha = "SHA"
        end
        context "valid fields" do
            before(:each) do
                post "sprints", {:title => @title, :description => @description, :project_id => @project_id }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                @sprint_result = @mysql_client.query("select * from sprints").first
                @sprint_state = @mysql_client.query("select * from sprint_states").first
                @timeline = @mysql_client.query("select * from sprint_timelines where sprint_id = #{@sprint_result["id"]}").first
                @sprint = JSON.parse(last_response.body)
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
        end
    end
    describe "GET /" do
        fixtures :projects, :sprints, :sprint_states
        before(:each) do
            project_id = projects(:demo).id
            get "/sprints?project_id=#{project_id}"
            res = JSON.parse(last_response.body)
            @sprint_results = @mysql_client.query("select * from sprints where project_id = #{project_id}")
            @project_result = @mysql_client.query("select * from projects where id = #{project_id}").first
            @project = res[0]["project"]
            @sprints = res
        end

        it_behaves_like "project"
        it_behaves_like "sprints"
    end

    describe "GET /:id" do
        fixtures :projects, :sprints, :sprint_states, :states, :contributors, :comments, :user_profiles, :user_positions
        before(:each) do
            sprint = sprints(:sprint_1)
            get "/sprints/#{sprint.id}", {}, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
            res = JSON.parse(last_response.body)
            @sprint_result = @mysql_client.query("select * from sprints where id = #{sprint.id}").first
            @project_result = @mysql_client.query("select * from projects where id = #{sprint.project_id}").first
            @sprint_state_result = @mysql_client.query("select * from sprint_states where sprint_id = #{sprint.id}")
            @contributor_result = @mysql_client.query("select * from contributors where sprint_state_id = #{sprint_states(:sprint_1_state_1).id}") 
            @project = res["project"]
            @sprint = res
            @sprint_state = res["sprint_states"]
            @contributors = res["sprint_states"][0]["contributors"]
            @contributor_comment_result = @mysql_client.query("select * from comments where sprint_state_id = #{sprint_states(:sprint_1_state_1).id} and contributor_id = #{res["sprint_states"][0]["contributors"][0]["id"]}")
            @contributor_comments = res["sprint_states"][0]["contributors"][0]["comments"]
            @profile = user_profiles(:adam_confirmed)
            @position = user_positions(:adam_confirmed)
        end

        it_behaves_like "project"
        it_behaves_like "sprint"
        it_behaves_like "sprint_states"
        it_behaves_like "contributors"
        it_behaves_like "contributor_comments"
        it_behaves_like "comment_profile"
    end
end

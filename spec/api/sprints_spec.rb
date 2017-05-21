require_relative '../spec_helper'
require_relative '../api_spec_helper'

describe "/sprints" do
    
    fixtures :users

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
        context "invalid fields" do
            after(:each) do
                expect(last_response.status).to eq 400
                expect(@mysql_client.query("select * from sprints").count).to eq 0
            end
            context "title < 6 chars" do
                it "should return error message" do
                    post "sprints", {:title => "ABCDE", :description => @description, :project_id => @project_id }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                    res = JSON.parse(last_response.body)
                    expect(res["error"]).to eq "Please enter a more descriptive title"
                end
            end
            context "description < 6 chars" do
                it "should return error message" do
                    post "sprints", {:title => @title, :description => "12345", :project_id => @project_id }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                    res = JSON.parse(last_response.body) 
                    expect(res["error"]).to eq "Please enter a more detailed description"
                end
            end

        end
        context "valid fields" do
            before(:each) do
                post "sprints", {:title => @title, :description => @description, :project_id => @project_id }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                @sprint_result = @mysql_client.query("select * from sprints").first
                @sprint_state = @mysql_client.query("select * from sprint_states").first
                @timeline = @mysql_client.query("select * from sprint_timelines where sprint_id = #{@sprint_result["id"]}").first
                @sprint = JSON.parse(last_response.body)
            end
            it_behaves_like "sprint"
            context "sprint_states" do
                it "should include sprint_id" do
                    expect(@sprint_state["sprint_id"]).to eq @sprint["id"]
                end
                it "should include idea state_id" do
                    expect(@sprint_state["state_id"]).to eq(states(:idea).id)
                end
            end
            context "sprint_timeline" do
                it "should include sprint_id" do
                    expect(@timeline["sprint_id"]).to eq(@sprint["id"])
                end
                it "should include idea state_id" do
                    expect(@timeline["state_id"]).to eq(states(:idea).id)
                end
            end
        end
    end
    describe "GET /" do
        fixtures :projects, :sprints, :sprint_states
        before(:each) do
            project_id = projects(:demo).id
            get "/sprints?project_id=#{project_id}"
            @sprints = JSON.parse(last_response.body)
            @sprint_results = @mysql_client.query("select * from sprints where project_id = #{project_id}")
        end
        it_behaves_like "sprints"
    end

    describe "GET /:id" do
        fixtures :projects, :sprints, :sprint_states
        before(:each) do
            sprint = sprints(:sprint_1)
            get "/sprints/#{sprint.id}", {}, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
            @sprint = JSON.parse(last_response.body)
            @sprint_result = @mysql_client.query("select * from sprints where id = #{sprint.id}").first
        end
        it_behaves_like "sprint"
    end
end

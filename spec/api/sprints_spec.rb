require_relative '../spec_helper'
require_relative '../api_spec_helper'

describe "/sprints" do
    
    fixtures :users, :projects, :states

    shared_examples_for "sprints" do
        it "should return id" do
            @sprint_results.each_with_index do |sprint_result,i|
                expect(@sprints[i]["id"]).to eq(sprint_result["id"])
            end
        end
        it "should return user_id" do
            @sprint_results.each_with_index do |sprint_result,i|
                expect(@sprints[i]["user_id"]).to eq(sprint_result["user_id"])
            end
        end
        it "should return title" do
            @sprint_results.each_with_index do |sprint_result,i|
                expect(@sprints[i]["title"]).to eq(sprint_result["title"])
            end
        end
        it "should return description" do
            @sprint_results.each_with_index do |sprint_result,i|
                expect(@sprints[i]["description"]).to eq(sprint_result["description"])
            end
        end
        it "should return sha" do
            @sprint_results.each_with_index do |sprint_result,i|
                expect(@sprints[i]["sha"]).to eq(sprint_result["sha"])
            end
        end
        it "should return winner_id" do
            @sprint_results.each_with_index do |sprint_result,i|
                expect(@sprints[i]["winner_id"]).to eq(sprint_result["winner_id"])
            end
        end
    end

    describe "POST /" do
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
            context "non-existing project" do
                it "should return error message" do
                    post "sprints", {:title => @title, :description => @description, :project_id => 993 }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                    res = JSON.parse(last_response.body)
                    expect(res["error"]).to eq "This project does not exist"
                end
            end
        end
        context "valid fields" do
            before(:each) do
                post "sprints", {:title => @title, :description => @description, :project_id => @project_id }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                @sprint_results = @mysql_client.query("select * from sprints")
                @sprint_state = @mysql_client.query("select * from sprint_states").first
                @timeline = @mysql_client.query("select * from sprint_timelines where sprint_id = #{@sprint_results.first["id"]}").first
                @sprints = [JSON.parse(last_response.body)]
            end
            it_behaves_like "sprints"
            context "sprint_states" do
                it "should include sprint_id" do
                    expect(@sprint_state["sprint_id"]).to eq @sprints[0]["id"]
                end
                it "should include idea state_id" do
                    expect(@sprint_state["state_id"]).to eq(states(:idea).id)
                end
            end
            context "sprint_timeline" do
                it "should include sprint_id" do
                    expect(@timeline["sprint_id"]).to eq(@sprints[0]["id"])
                end
                it "should include idea state_id" do
                    expect(@timeline["state_id"]).to eq(states(:idea).id)
                end
            end
        end
    end
    describe "GET /" do
        fixtures :sprints, :sprint_states
        context "valid params" do
            context "filter by" do
                context "project_id", :focus => true do
                    before(:each) do
                        project_id = projects(:demo).id
                        get "/sprints?project_id=#{project_id}"
                        @sprints = JSON.parse(last_response.body)
                        @sprint_results = @mysql_client.query("select sprints.* from sprints INNER JOIN sprint_states ON sprint_states.sprint_id = sprints.id INNER JOIN (SELECT MAX(id) last_id FROM sprint_states GROUP BY sprint_id) last_sprint_state ON sprint_states.id = last_sprint_state.last_id where project_id = #{project_id}")
                    end
                    it_behaves_like "sprints"
                end
                context "sprint_states.state_id" do
                    before(:each) do
                        skip "this has been tested and works but activerecord does not return the queried record from rspec..."
                        state_id = sprint_states(:sprint_1_state_1).state_id
                        project_id = projects(:demo).id
                        get "/sprints?project_id=#{project_id}&sprint_states.state_id=#{state_id}"
                        @sprints = JSON.parse(last_response.body)
                        @sprint_results = @mysql_client.query("select sprints.* from sprints INNER JOIN sprint_states ON sprint_states.sprint_id = sprints.id INNER JOIN (SELECT MAX(id) last_id FROM sprint_states GROUP BY sprint_id) last_sprint_state ON sprint_states.id = last_sprint_state.last_id where sprint_states.state_id = #{state_id} AND project_id = #{project_id}")
                    end
                    it_behaves_like "sprints"
                end
                context "id" do
                    before(:each) do
                        id = sprints(:sprint_1).id
                        get "/sprints?id=#{id}"
                        @sprints = JSON.parse(last_response.body)
                        @sprint_results = @mysql_client.query("select sprints.* from sprints INNER JOIN sprint_states ON sprint_states.sprint_id = sprints.id INNER JOIN (SELECT MAX(id) last_id FROM sprint_states GROUP BY sprint_id) last_sprint_state ON sprint_states.id = last_sprint_state.last_id where sprints.id = #{id}")
                    end
                    it_behaves_like "sprints"
                end
            end
        end
    end
    describe "GET /:id" do
        fixtures :sprints, :sprint_states
        before(:each) do
            sprint = sprints(:sprint_1)
            get "/sprints/#{sprint.id}", {}, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
            @sprints = [JSON.parse(last_response.body)]
            @sprint_results = @mysql_client.query("select * from sprints where id = #{sprint.id}")
        end
        it_behaves_like "sprints"
    end
end

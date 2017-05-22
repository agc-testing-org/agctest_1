require_relative '../spec_helper'
require_relative '../api_spec_helper'

describe "/sprints-states" do

    fixtures :users
    
    shared_examples_for "sprint_state" do
        it "should return id" do
            expect(@sprint_state["id"]).to eq(@sprint_state_result["id"])
        end
        it "should return sprint_id" do
            expect(@sprint_state["sprint_id"]).to eq(@sprint_state_result["sprint_id"])
        end
        it "should return sha" do
            expect(@sprint_state["sha"]).to eq(@sprint_state_result["sha"])
        end
        it "should return state" do
            expect(@sprint_state["state_id"]).to eq(@sprint_state_result["state_id"])
        end
        it "should return active_contribution_id (last 'join' by signed in user)" do
            if @sprint_state["contributors"] && @sprint_state["contributors"].length > 0
                @contributor_result.each do |c|
                    if c["user_id"] == @user
                        expect(@sprint_state["active_contribution_id"]).to eq(c["id"])
                    end
                end
            end
        end
    end

    shared_examples_for "sprint_states" do
        it "should return more than one result" do
            expect(@sprint_states.length).to be > 0
        end

        if @sprint_state_results
            @sprint_state_results.each_with_index do |s,i|
                @sprint_state_result = s
                @sprint_state = @sprint_states[i]
                it_should_behave_like "sprint_state"
            end
        end
    end

    shared_examples_for "contributor" do
        it "should return id" do
            expect(@contributor["id"]).to eq(@contributor_result["id"])
        end
        context "when owned" do
            it "should return repo name" do
                if @user == @contributor_result["user_id"]
                    expect(@contributor["repo"]).to eq(@contributor_result["repo"])
                end
            end
        end
    end

    shared_examples_for "contributor_comment" do
        it "should return id" do           
            expect(@contributor_comment["id"]).to eq(@contributor_comment_result["id"])
        end
        it "should return text" do
            expect(@contributor_comment["text"]).to eq(contributor_comment_result["text"])
        end
    end

    shared_examples_for "comment_profile" do
        it "should return location" do
            expect(@contributor_comment["user_profile"]["location"]).to eq(@profile.location_name)
        end
        it "should return title" do
            expect(@contributor_comment["user_profile"]["title"]).to eq(@position.title)
        end
        it "should return industry" do
            expect(@contributor_comment["user_profile"]["industry"]).to eq(@position.industry)
        end
        it "should return size" do
            expect(@contributor_comment["user_profile"]["size"]).to eq(@position.size)
        end
    end

    describe "POST /" do
        fixtures :projects, :sprints, :states, :sprint_states
        before(:each) do
            body = { 
                :name=>"1", 
                :commit=>{
                    :sha=>sprint_states(:sprint_1_state_1).sha
                }
            }

            @body = JSON.parse(body.to_json, object_class: OpenStruct)
            Octokit::Client.any_instance.stub(:branch => @body)
        end
        context "admin" do
            before(:each) do
                post "/sprint-states", {:sprint => sprints(:sprint_1).id, :state => states(:backlog).id }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@admin_w7_token}"}
                @sprint_state = JSON.parse(last_response.body)
                @sprint_state_result = @mysql_client.query("select * from sprint_states where sprint_id = #{sprints(:sprint_1).id} ORDER BY id DESC").first 
            end
            it "should return current master branch sha" do
                expect(@sprint_state_result["sha"]).to eq(sprint_states(:sprint_1_state_1).sha)
            end
            it_behaves_like "sprint_state"
        end
        context "unauthorized" do
            before(:each) do
                post "/sprint-states", {:sprint => sprints(:sprint_1).id, :state => states(:backlog).id }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
            end
            it_behaves_like "unauthorized"
        end
    end

    describe "GET /" do
        fixtures :projects, :sprints, :states, :sprint_states 
        context "valid params" do
            context "filter by" do
                context "sprint_id" do
                    before(:each) do
                        sprint_id = sprints(:sprint_1).id
                        get "/sprint-states?sprint_id=#{sprint_id}"
                        @sprint_states = JSON.parse(last_response.body)
                        @sprint_state_results = @mysql_client.query("select * from sprint_states where sprint_id = #{sprint_id}")
                    end
                    it_behaves_like "sprint_states"
                end
            end
        end
    end
end

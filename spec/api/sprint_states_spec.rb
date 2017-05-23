require 'spec_helper'
require 'api_helper'

describe "/sprints-states" do

    fixtures :users, :projects, :sprints, :states

    shared_examples_for "sprint_states" do
        it "should return id" do
            @sprint_state_results.each_with_index do |sprint_state_result,i|
                expect(@sprint_states[i]["id"]).to eq(sprint_state_result["id"])
            end
        end
        it "should return sprint_id" do
            @sprint_state_results.each_with_index do |sprint_state_result,i|
                expect(@sprint_states[i]["sprint_id"]).to eq(sprint_state_result["sprint_id"])
            end
        end
        it "should return sha" do
            @sprint_state_results.each_with_index do |sprint_state_result,i|
                expect(@sprint_states[i]["sha"]).to eq(sprint_state_result["sha"])
            end
        end
        it "should return state" do
            @sprint_state_results.each_with_index do |sprint_state_result,i|
                expect(@sprint_states[i]["state_id"]).to eq(sprint_state_result["state_id"])
            end
        end
    end

    shared_examples_for "contributors" do
        it "should return id" do
            @contributor_results.each_with_index do |contributor_result,i|
                expect(@contributors[i]["id"]).to eq(contributor_result["id"])
            end
        end
        context "when owned" do
            it "should return repo name" do
                @contributor_results.each_with_index do |contributor_result,i|                    
                    if @user == contributor_result["user_id"]
                        expect(@contributors[i]["repo"]).to eq(contributor_result["repo"])
                    end
                end
            end
            it "should return active_contribution_id (last 'join' by signed in user)" do
                @contributor_results.each_with_index do |contributor_result,i|
                    if @user == contributor_result["user_id"]
                        expect(@sprint_state["active_contribution_id"]).to eq(contributor_result["id"])
                    end
                end
            end
        end
    end

    shared_examples_for "contributor_comments" do
        it "should return id" do           
            expect(@contributor_comment["id"]).to eq(@contributor_comment_result["id"])
        end
        it "should return text" do
            expect(@contributor_comment["text"]).to eq(@contributor_comment_result["text"])
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
        fixtures :sprint_states
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
                @sprint_states = [JSON.parse(last_response.body)]
                @sprint_state_results = @mysql_client.query("select * from sprint_states where sprint_id = #{sprints(:sprint_1).id} AND id = #{@sprint_states[0]["id"]} ORDER BY id DESC")
            end
            it "should return current master branch sha" do
                expect(@sprint_state_results.first["sha"]).to eq(sprint_states(:sprint_1_state_1).sha)
            end
            it_behaves_like "sprint_states"
        end
        context "unauthorized" do
            before(:each) do
                post "/sprint-states", {:sprint => sprints(:sprint_1).id, :state => states(:backlog).id }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
            end
            it_behaves_like "unauthorized"
        end
    end

    describe "GET /" do
        fixtures :sprint_states
        context "valid params" do
            context "filter by" do
                context "sprint_id" do
                    before(:each) do
                        sprint_id = sprint_states(:sprint_1_state_1).sprint_id
                        get "/sprint-states?sprint_id=#{sprint_id}"
                        @sprint_states = JSON.parse(last_response.body)
                        @sprint_state_results = @mysql_client.query("select * from sprint_states where sprint_id = #{sprint_id}")
                    end
                    it_behaves_like "sprint_states"
                end
            end
            context "with contributors (owned) and comments", :focus => true do
                fixtures :contributors, :comments
                before(:each) do
                    sprint_state_id = sprint_states(:sprint_1_state_1).id
                    get "/sprint-states?id_id=#{sprint_state_id}", {}, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                    @sprint_state = JSON.parse(last_response.body)[0]
                    @contributors = @sprint_state["contributors"]
                    @contributor_results = @mysql_client.query("select * from contributors where contributors.sprint_state_id = #{sprint_state_id}")
                end
                it_behaves_like "contributors"
                #it_behaves_like "contributor_comments" #TODO
            end
        end
    end
end

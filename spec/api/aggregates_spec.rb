require 'spec_helper'
require 'api_spec_helper'

describe "/aggregate-*" do

    fixtures :users

    shared_examples_for "aggregate_comments" do
        context "user created" do
            it "should return comments based on filter" do
                expect(@res["author"][comments(:adam_confirmed_1).sprint_state.state_id.to_s][0]["user_id"]).to eq(comments(:adam_admin_1).user_id)
            end
        end
        context "user received" do
            it "should return comments based on filter" do
                expect(@res["receiver"][comments(:adam_admin_1).sprint_state.state_id.to_s][0]["id"]).to eq(comments(:adam_admin_1).contributor_id)
            end
        end
    end

    describe "GET /aggregate-comments" do
        fixtures :users, :projects, :sprints, :sprint_states, :contributors, :comments
        context "user_id parameter" do
            before(:each) do
                get "/aggregate-comments?user_id=#{users(:adam_confirmed).id}",{}, {}
                @res = JSON.parse(last_response.body)
            end
            it_behaves_like "aggregate_comments"
        end
        context "no user_id" do
            context "signed in" do
                before(:each) do
                    get "/aggregate-comments",{}, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
                    @res = JSON.parse(last_response.body)
                end
                it_behaves_like "aggregate_comments"
            end
            context "not signed" do
                before(:each) do
                    get "/aggregate-comments",{}, {}
                end 
                it "should return 404" do
                    expect(last_response.status).to eq(404)
                end
            end
        end
    end

    shared_examples_for "aggregate_votes" do
        context "user created" do
            it "should return votes based on filter" do
                expect(@res["author"][votes(:adam_confirmed_1).sprint_state.state_id.to_s][0]["user_id"]).to eq(votes(:adam_admin_1).user_id)
            end
        end
        context "user received" do
            it "should return votes based on filter" do
                expect(@res["receiver"][votes(:adam_admin_1).sprint_state.state_id.to_s][0]["id"]).to eq(votes(:adam_admin_1).contributor_id)
            end
        end
    end

    describe "GET /aggregate-votes" do
        fixtures :users, :projects, :sprints, :sprint_states, :contributors, :votes
        context "user_id parameter" do
            before(:each) do
                get "/aggregate-votes?user_id=#{users(:adam_confirmed).id}",{}, {}
                @res = JSON.parse(last_response.body)
            end 
            it_behaves_like "aggregate_votes"
        end
        context "no user_id" do
            context "signed in" do
                before(:each) do
                    get "/aggregate-votes",{}, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
                    @res = JSON.parse(last_response.body)
                end
                it_behaves_like "aggregate_votes"
            end
            context "not signed" do
                before(:each) do
                    get "/aggregate-votes",{}, {}
                end
                it "should return 404" do
                    expect(last_response.status).to eq(404)
                end 
            end
        end 
    end

    shared_examples_for "aggregate_contributors" do
        context "user contributed" do
            it "should return contributions based on filter" do
                expect(@res["author"][contributors(:adam_confirmed_1).sprint_state.state_id.to_s][0]["user_id"]).to eq(contributors(:adam_confirmed_1).user_id)
            end
        end
        context "user won" do
            it "should return contributions based on filter" do
                expect(@res["receiver"][contributors(:adam_confirmed_1).sprint_state.state_id.to_s][0]["user_id"]).to eq(contributors(:adam_confirmed_1).user_id)
            end
        end
    end

    describe "GET /aggregate-contributors" do
        fixtures :users, :projects, :sprints, :sprint_states, :contributors
        context "user_id parameter" do
            before(:each) do
                @mysql_client.query("update sprint_states set contributor_id = #{contributors(:adam_confirmed_1).id}")
                get "/aggregate-contributors?user_id=#{users(:adam_confirmed).id}",{}, {}
                @res = JSON.parse(last_response.body)
            end
            it_behaves_like "aggregate_contributors"
        end
        context "no user_id" do
            context "signed in" do
                before(:each) do
                    @mysql_client.query("update sprint_states set contributor_id = #{contributors(:adam_confirmed_1).id}")
                    get "/aggregate-contributors",{}, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
                    @res = JSON.parse(last_response.body)
                end
                it_behaves_like "aggregate_contributors"
            end
            context "not signed" do
                before(:each) do
                    get "/aggregate-contributors",{}, {}
                end
                it "should return 404" do
                    expect(last_response.status).to eq(404)
                end
            end
        end 
    end
 end

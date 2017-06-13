require 'spec_helper'
require 'api_helper'

describe "/contributors" do

    fixtures :users, :seats

    before(:all) do
        @CREATE_TOKENS=true
    end 

    describe "POST /:id/comments" do
        fixtures :projects, :sprints, :sprint_states, :contributors, :states
        before(:each) do
            @sprint_state_id = contributors(:adam_confirmed_1).sprint_state_id
            @contributor_id = contributors(:adam_confirmed_1).id
            @project = projects(:demo).id
        end
        context "valid comment" do
            before(:each) do
                @text = "AB"
                post "/contributors/#{@contributor_id}/comments", {:text => @text, :sprint_state_id => @sprint_state_id}.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
                @res = JSON.parse(last_response.body)
                @mysql = @mysql_client.query("select * from comments").first
                @sprint_timeline = @mysql_client.query("select * from sprint_timelines").first
            end
            it "should return comment id" do
                expect(@res["id"]).to eq(1)
            end
            context "comment" do
                it "should save text" do
                    expect(@mysql["text"]).to eq(@text)
                end
                it "should save contributor_id" do
                    expect(@mysql["contributor_id"]).to eq(@contributor_id)
                end
            end
            context "sprint_timelines" do
                it "should record sprint state id" do
                    expect(@sprint_timeline["sprint_state_id"]).to eq(@sprint_state_id)
                end
                it "should record comment id" do
                    expect(@sprint_timeline["comment_id"]).to eq(@res["id"])
                end
                it "should record contributor id" do
                    expect(@sprint_timeline["contributor_id"]).to eq(@contributor_id)
                end
            end
        end
        context "invalid comment" do
            it "should return error message" do
                post "/contributors/#{@contributor_id}/comments", {:text => "A", :sprint_state_id => @sprint_state_id}.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
                res = JSON.parse(last_response.body)
                expect(res["message"]).to eq("Please enter a more detailed comment")
            end
        end
    end

    describe "POST /:id/votes" do
        fixtures :projects, :sprints, :sprint_states, :contributors, :states
        before(:each) do
            @sprint_state_id = contributors(:adam_confirmed_1).sprint_state_id
            @contributor_id = contributors(:adam_confirmed_1).id
            @project = projects(:demo).id
            post "/contributors/#{@contributor_id}/votes", {:sprint_state_id => @sprint_state_id}.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
            @res = JSON.parse(last_response.body)
            @mysql = @mysql_client.query("select * from votes").first
            @sprint_timeline = @mysql_client.query("select * from sprint_timelines").first
        end
        it "should return vote id" do
            expect(@res["id"]).to eq(1)
        end
        it "should return created status true for a new vote" do
            expect(@res["created"]).to be true
        end
        context "votes" do
            it "should save contributor_id" do
                expect(@mysql["contributor_id"]).to eq(@contributor_id)
            end
            it "should save sprint_state_id" do
                expect(@mysql["sprint_state_id"]).to eq(@sprint_state_id)
            end
        end
        context "sprint_timelines" do
            it "should record sprint state id" do
                expect(@sprint_timeline["sprint_state_id"]).to eq(@sprint_state_id)
            end
            it "should record comment id" do
                expect(@sprint_timeline["vote_id"]).to eq(@res["id"])
            end 
            it "should record contributor id" do
                expect(@sprint_timeline["contributor_id"]).to eq(@contributor_id)
            end 
        end
        context "duplicate vote" do
            before(:each) do
                post "/contributors/#{@contributor_id}/votes", {:sprint_state_id => @sprint_state_id}.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
                @res = JSON.parse(last_response.body)
                @mysql = @mysql_client.query("select * from votes")
            end
            it "should return created status false" do
                expect(@res["created"]).to be false
            end
            it "should not create a new vote" do
                expect(@mysql.count).to eq(1)
            end
        end
        context "different vote" do
            before(:each) do
                @new_contributor_id = contributors(:adam_admin_1).id
                post "/contributors/#{@new_contributor_id}/votes", {:sprint_state_id => @sprint_state_id}.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
                @mysql = @mysql_client.query("select * from votes")
                @res = JSON.parse(last_response.body)
            end
            it "should update the contributor_id" do
                expect(@mysql.first["contributor_id"]).to eq(@new_contributor_id)
            end
            it "should return created status true" do
                expect(@res["created"]).to be true
            end
            it "should not create a new vote" do
                expect(@mysql.count).to eq(1)
            end
            it "should return previous vote" do
                expect(@res["previous"]).to eq(@contributor_id)
            end
        end
    end

    describe "POST /:id/winner" do
        fixtures :projects, :sprints, :sprint_states, :contributors
        before(:each) do
            @sprint_state_id = contributors(:adam_confirmed_1).sprint_state_id
            @contributor_id = contributors(:adam_confirmed_1).id
            @project = projects(:demo).id
            @pull_id = 222
            body = {
                :number => @pull_id,
                :name=>"1",
                :commit=>{
                    :sha=>sprint_states(:sprint_1_state_1).sha
                }
            }

            @body = JSON.parse(body.to_json, object_class: OpenStruct)
            Octokit::Client.any_instance.stub(:create_pull_request => @body)

            post "/contributors/#{@contributor_id}/winner", {:project_id => @project, :sprint_state_id => @sprint_state_id}.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
            @res = JSON.parse(last_response.body)
            @mysql = @mysql_client.query("select * from sprint_states").first
            @timeline = @mysql_client.query("select * from sprint_timelines").first
            @sprint_timeline = @mysql_client.query("select * from sprint_timelines").first
        end
        context "admin" do
            it "should return sprint_state id" do
                expect(@res["id"]).to eq(@sprint_state_id)
            end
            context "sprint_state" do
                it "should save contributor_id (winner)" do
                    expect(@mysql["contributor_id"]).to eq(@contributor_id)
                end
                it "should save arbiter (judge)" do
                    expect(@mysql["arbiter_id"]).to eq(users(:adam_admin).id)
                end
                it "should save pull request" do
                    expect(@mysql["pull_request"]).to eq(@pull_id)
                end
            end
            context "sprint_timelines" do
                it "should record sprint state id" do
                    expect(@sprint_timeline["sprint_state_id"]).to eq(@sprint_state_id)
                end
                it "should record contributor id" do
                    expect(@sprint_timeline["contributor_id"]).to eq(@contributor_id)
                end
            end
        end
    end

    describe "POST /:id/merge" do
        fixtures :projects, :sprints, :sprint_states, :contributors
        before(:each) do
            @sprint_state_id = contributors(:adam_confirmed_1).sprint_state_id
            @contributor_id = contributors(:adam_confirmed_1).id
            @project = projects(:demo).id
            @pull_id = 222
            body = {
                :number => @pull_id,
                :name=>"1",
                :commit=>{
                    :sha=>sprint_states(:sprint_1_state_1).sha
                }
            }

            @body = JSON.parse(body.to_json, object_class: OpenStruct)
            Octokit::Client.any_instance.stub(:create_pull_request => @body)
            Octokit::Client.any_instance.stub(:merge_pull_request => @body)
            post "/contributors/#{@contributor_id}/winner", {:project_id => @project, :sprint_state_id => @sprint_state_id}.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
            post "/contributors/#{@contributor_id}/merge", {:project_id => @project, :sprint_state_id => @sprint_state_id}.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
            @res = JSON.parse(last_response.body)
            @mysql = @mysql_client.query("select * from sprint_states").first
        end
        context "admin" do
            it "should return sprint_state id" do
                expect(@res["id"]).to eq(@sprint_state_id)
            end
            context "sprint_state" do
                it "should update merged" do
                    expect(@mysql["merged"]).to eq(1)
                end
            end
        end
    end
end

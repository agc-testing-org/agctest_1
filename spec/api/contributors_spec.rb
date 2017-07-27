require 'spec_helper'
require 'api_helper'

describe "/contributors" do

    fixtures :users, :seats, :states, :notifications

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

    shared_examples_for "sprint_timelines_for_feedback_actions" do
        it "should record sprint state id" do
            expect(@sprint_timeline["sprint_state_id"]).to eq(@sprint_state_id)
        end
        it "should record contributor id" do
            expect(@sprint_timeline["contributor_id"]).to eq(@contributor_id)
        end
        it "should record next_sprint_state_id" do
            expect(@sprint_timeline["next_sprint_state_id"]).to eq(sprint_states(:sprint_1_state_2).id)
        end
    end

    shared_examples_for "contributors_post" do
        context "contributor" do
            it "should include repo name" do
                expect(@sql["repo"]).to_not be nil
            end
            it "should include user_id" do
                expect(@sql["user_id"]).to eq(decrypt(users(:adam_confirmed).id).to_i)
            end
            it "should include sprint_state_id" do
                expect(@sql["sprint_state_id"]).to eq(@sprint_state_id)
            end
            it "should set prepared = 1" do
                expect(@sql["prepared"]).to eq 1
            end
            it "should set preparing = 0" do
                expect(@sql["preparing"]).to eq 0
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

    describe "POST /contributors" do
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
                post "/contributors", {:sprint_state_id => @sprint_state_id }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
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
                post "/contributors", {:sprint_state_id => @sprint_state_id }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
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
                post "/contributors", {:sprint_state_id => @sprint_state_id }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
            end
            it_behaves_like "not_found"
        end
        context "sprint_state_id with contributor = false" do
            fixtures :sprint_states, :states,  :projects
            before(:each) do
                @sprint_state_id = sprint_states(:sprint_1_no_contributors).id
                @project = projects(:demo).id
                post "/contributors", {:sprint_state_id => @sprint_state_id }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                @res = JSON.parse(last_response.body)
            end
            it_behaves_like "error", "unable to join this phase"
        end
    end

    describe "GET /contributors/:contributor_id" do
        fixtures :projects, :sprints, :sprint_states, :contributors
        before(:each) do
            @project = projects(:demo).id
        end
        context "valid contributor" do
            before(:each) do
                get "/contributors/#{contributors(:adam_confirmed_1).id}", {}, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                @sql = @mysql_client.query("select * from contributors where user_id = #{decrypt(contributors(:adam_confirmed_1).user_id)} ORDER BY ID DESC").first
                @res = JSON.parse(last_response.body)
            end
            it "should return contributor id" do
                expect(@res["id"]).to eq(@sql["id"])
            end
        end
    end

    describe "PATCH /contributors/:contributor_id" do
        fixtures :projects, :sprints, :sprint_states, :contributors
        before(:each) do
            Octokit::Client.any_instance.stub(:login) { @username }
            Octokit::Client.any_instance.stub(:create_repository) { {} }

            body = {
                :name=>"1",
                :commit=>{
                    :sha=>contributors(:adam_confirmed_1).commit
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
                patch "/contributors/#{contributors(:adam_confirmed_1).id}", {}, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                @res = JSON.parse(last_response.body)
                @sql = @mysql_client.query("select * from contributors where user_id = #{decrypt(contributors(:adam_confirmed_1).user_id)} ORDER BY ID DESC").first
            end
            context "contributor" do
                it "should include commit" do
                    expect(@sql["commit"]).to eq(contributors(:adam_confirmed_1).commit)
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
                patch "/contributors/33", {}, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                @res = JSON.parse(last_response.body)
            end
            it_behaves_like "not_found"
        end
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
                post "/contributors/#{@contributor_id}/comments", {:text => @text, :sprint_state_id => @sprint_state_id}.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
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
                it "should record comment id" do
                    expect(@sprint_timeline["comment_id"]).to eq(@res["id"])
                end
                it "should set notification_id = comment" do
                    expect(@sprint_timeline["notification_id"]).to eq(notifications(:comment).id)
                end
                it_behaves_like "sprint_timelines_for_feedback_actions"
            end
        end
        context "invalid comment" do
            context "< 2 char" do
                before(:each) do
                    post "/contributors/#{@contributor_id}/comments", {:text => "A", :sprint_state_id => @sprint_state_id}.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                end
                it_behaves_like "error", "comments must be 2-5000 characters"
            end
            context "greater than 5000 characters" do
                before(:each) do
                    post "/contributors/#{@contributor_id}/comments", {:text => "A"*5001, :sprint_state_id => @sprint_state_id}.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                end
                it_behaves_like "error", "comments must be 2-5000 characters"
            end
            context "invalid id" do
                before(:each) do
                    post "/contributors/76262/comments", {:text => "AA", :sprint_state_id => @sprint_state_id}.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                end
                it_behaves_like "error", "unable to save comment"
            end
        end
    end

    describe "POST /:id/votes" do
        fixtures :projects, :sprints, :sprint_states, :contributors, :states
        before(:each) do
            @sprint_state_id = contributors(:adam_confirmed_1).sprint_state_id
            @contributor_id = contributors(:adam_confirmed_1).id
            @project = projects(:demo).id
            post "/contributors/#{@contributor_id}/votes", {:sprint_state_id => @sprint_state_id}.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
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
            it "should record vote id" do
                expect(@sprint_timeline["vote_id"]).to eq(@res["id"])
            end 
            it "should set notification_id = vote" do
                expect(@sprint_timeline["notification_id"]).to eq(notifications(:vote).id)
            end  
            it_behaves_like "sprint_timelines_for_feedback_actions"
        end
        context "duplicate vote" do
            before(:each) do
                post "/contributors/#{@contributor_id}/votes", {:sprint_state_id => @sprint_state_id}.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
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
                post "/contributors/#{@new_contributor_id}/votes", {:sprint_state_id => @sprint_state_id}.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
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

            post "/contributors/#{@contributor_id}/winner", {:project_id => @project, :sprint_state_id => @sprint_state_id}.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@admin_w7_token}"}
            @res = JSON.parse(last_response.body)
            @mysql = @mysql_client.query("select * from sprint_states").first
            @timeline = @mysql_client.query("select * from sprint_timelines").first
            @sprint_timeline = @mysql_client.query("select * from sprint_timelines").first
        end
        context "valid" do
            context "admin" do
                it "should return sprint_state id" do
                    expect(@res["id"]).to eq(@sprint_state_id)
                end
                context "sprint_state" do
                    it "should save contributor_id (winner)" do
                        expect(@mysql["contributor_id"]).to eq(@contributor_id)
                    end
                    it "should save arbiter (judge)" do
                        expect(@mysql["arbiter_id"]).to eq(decrypt(users(:adam_admin).id).to_i)
                    end
                    it "should save pull request" do
                        expect(@mysql["pull_request"]).to eq(@pull_id)
                    end
                end
                context "sprint_timelines" do
                    it "should set notification_id = winner" do
                        expect(@sprint_timeline["notification_id"]).to eq(notifications(:winner).id)
                    end  
                    it_behaves_like "sprint_timelines_for_feedback_actions"
                end
            end
        end
        context "invalid" do
            context "sprint state" do
                before(:each) do
                    post "/contributors/#{@contributor_id}/winner", {:project_id => @project, :sprint_state_id => 787}.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@admin_w7_token}"}
                end
                it_behaves_like "not_found"
            end
            context "contributor" do
                before(:each) do
                    post "/contributors/787/winner", {:project_id => @project, :sprint_state_id => @sprint_state_id}.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@admin_w7_token}"}
                end
                it_behaves_like "error", "unable to set winner"
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
        end
        context "valid" do
            context "admin" do
                before(:each) do
                    post "/contributors/#{@contributor_id}/winner", {:project_id => @project, :sprint_state_id => @sprint_state_id}.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@admin_w7_token}"}
                    post "/contributors/#{@contributor_id}/merge", {:project_id => @project, :sprint_state_id => @sprint_state_id}.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@admin_w7_token}"}
                    @res = JSON.parse(last_response.body)
                    @mysql = @mysql_client.query("select * from sprint_states").first
                end
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
        context "invalid" do
            context "sprint state" do
                before(:each) do
                    post "/contributors/#{@contributor_id}/merge", {:project_id => @project, :sprint_state_id => 1221}.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@admin_w7_token}"}
                end
                it_behaves_like "not_found"
            end
            context "no winner" do
                before(:each) do
                    @mysql_client.query("update sprint_states set contributor_id = null where id = #{@sprint_state_id}")
                    post "/contributors/#{@contributor_id}/merge", {:project_id => @project, :sprint_state_id => @sprint_state_id}.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@admin_w7_token}"}
                end
                it_behaves_like "error", "a contribution has not been selected"
            end

        end
    end
end

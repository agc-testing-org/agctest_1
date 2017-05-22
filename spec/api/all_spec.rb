require_relative '../spec_helper'
require_relative '../api_spec_helper'

describe "/sprints-states" do
    shared_examples_for "sprint_states" do
        it "should return id" do
            @sprint_state_result.each_with_index do |s,i|
                expect(@sprint_state[i]["id"]).to eq(s["id"])
            end
        end
        it "should return deadline" do
            @sprint_state_result.each_with_index do |s,i|
                expect(@sprint_state[i]["deadline"]).to_not be nil
            end
        end
        it "should return state" do
            @sprint_state_result.each_with_index do |s,i|
                expect(@sprint_state[i]["state"]["id"]).to eq(s["state_id"])
            end
        end
        it "should return active_contribution_id (last 'join' by signed in user)" do
            @sprint_state_result.each_with_index do |s,i|
                if @sprint_state[i]["contributors"].length > 0
                    @contributor_result.each do |c|
                        if c["user_id"] == @user
                            expect(@sprint_state[i]["active_contribution_id"]).to eq(c["id"])
                        end
                    end
                end
            end
        end
    end

    shared_examples_for "contributors" do
        it "should return id" do
            @contributor_result.each_with_index do |c,i|
                expect(@contributors[i]["id"]).to eq(c["id"])
            end
        end
        context "when owned" do
            it "should return repo name" do
                @contributor_result.each_with_index do |c,i|
                    if @user == c["user_id"]
                        expect(@contributors[i]["repo"]).to eq(c["repo"])
                    end
                end
            end
        end
    end

    shared_examples_for "contributor_comments" do
        it "should return id" do
            @contributor_comment_result.each_with_index do |c,i|
                expect(@contributor_comments[i]["id"]).to eq(c["id"])
            end
        end
        it "should return text" do
            @contributor_comment_result.each_with_index do |c,i|
                expect(@contributor_comments[i]["text"]).to eq(c["text"])
            end
        end
    end

    shared_examples_for "comment_profile" do
        it "should return location" do
            expect(@contributor_comments[0]["user_profile"]["location"]).to eq(@profile.location_name)
        end
        it "should return title" do
            expect(@contributor_comments[0]["user_profile"]["title"]).to eq(@position.title)
        end
        it "should return industry" do
            expect(@contributor_comments[0]["user_profile"]["industry"]).to eq(@position.industry)
        end
        it "should return size" do
            expect(@contributor_comments[0]["user_profile"]["size"]).to eq(@position.size)
        end
    end

    describe "GET /:id/events" do
        fixtures :users, :sprints, :labels, :states, :projects, :sprint_timelines
        context "no filter" do
            before(:each) do
                project_id = projects(:demo).id
                get "/projects/#{project_id}/events"
                @timeline = JSON.parse(last_response.body)
                @timeline_result = @mysql_client.query("select * from sprint_timelines where project_id = #{project_id}")
            end
            it_behaves_like "sprint_timeline"
        end
        context "filter by sprint_id" do
            before(:each) do
                project_id = projects(:demo).id
                @sprint_id = sprints(:sprint_1).id
                get "/projects/#{project_id}/events?sprint_id=#{@sprint_id}"
                @timeline = JSON.parse(last_response.body)
                @timeline_result = @mysql_client.query("select * from sprint_timelines where sprint_id = #{@sprint_id}")
            end
            it "should return only sprint_1 events" do
                @timeline_result.each_with_index do |t,i|
                    expect(@timeline[i]["sprint"]["id"]).to eq(@sprint_id)
                end
            end
            it_behaves_like "sprint_timeline"
        end
    end

    describe "PATCH /sprints/:id" do
        fixtures :projects, :sprints, :sprint_states, :states
        before(:each) do
            body = { 
                :name=>"1", 
                :commit=>{
                    :sha=>sprint_states(:sprint_1_state_1).sha
                }
            }

            @body = JSON.parse(body.to_json, object_class: OpenStruct)
            Octokit::Client.any_instance.stub(:branch => @body)

            sprint = sprints(:sprint_1)
            patch "/sprints/#{sprint.id}", {:state_id => states(:idea).id }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@admin_w7_token}"}
            @res = JSON.parse(last_response.body)
            @sprint_result = @mysql_client.query("select * from sprint_states where sprint_id = #{sprint.id} ORDER BY id DESC").first 
        end

        context "sprint_state" do
            it "should save sprint_id" do
                expect(@sprint_result["sprint_id"]).to eq(sprints(:sprint_1).id)
            end
            it "should save state_id" do
                expect(@sprint_result["state_id"]).to eq(states(:idea).id)
            end
            it "should save sha" do
                expect(@sprint_result["sha"]).to eq(sprint_states(:sprint_1_state_1).sha)
            end
        end
        context "response" do
            it "should include sprint_id" do
                expect(@res["id"]).to eq(sprints(:sprint_1).id)
            end
            it "should include state_id" do
                expect(@res["sprint_states"][@res["sprint_states"].length - 1]["state"]["id"]).to eq(states(:idea).id)
            end
        end
    end
    describe "POST /projects/:id/refresh" do
        fixtures :projects, :sprints, :sprint_states, :contributors
        before(:each) do
            Octokit::Client.any_instance.stub(:login) { @username }
            Octokit::Client.any_instance.stub(:create_repository) { {} }

            body = {
                :name=>"1",
                :commit=>{
                    :sha=>sprint_states(:sprint_1_state_1).sha
                }
            }

            @body = JSON.parse(body.to_json, object_class: OpenStruct)
            Octokit::Client.any_instance.stub(:branch => @body)
        end
        context "valid project" do
            fixtures :users, :sprint_states, :states, :projects
            before(:each) do
                @sprint_state_id = sprint_states(:sprint_1_state_1).id
                @project = projects(:demo).id
                post "/projects/#{@project}/contributors", {:sprint_state_id => @sprint_state_id }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
                %x(cd #{@uri_master}; git checkout master; echo "changing" > newfile; git add .; git commit -m"new commit")
                @head = %x(cd #{@uri_master}; git log)
                %x(cd #{@uri}; git checkout -b "nb")
                post "/projects/#{@project}/refresh", {}, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
                @res = JSON.parse(last_response.body)
            end
            context "repo" do
                before(:each) do
                    @git = %x(cd #{@uri}; git checkout master; git log)
                end
                it "should update head" do
                    expect(@git).to eq(@head)
                end
            end
        end
    end

    describe "POST /projects/:id/contributors" do
        fixtures :projects, :sprints, :sprint_states, :contributors
        before(:each) do
            Octokit::Client.any_instance.stub(:login) { @username }
            Octokit::Client.any_instance.stub(:create_repository) { {} }

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
            fixtures :users, :sprint_states, :states, :projects
            before(:each) do
                @sprint_state_id = sprint_states(:sprint_1_state_1).id
                @project = projects(:demo).id
                post "/projects/#{@project}/contributors", {:sprint_state_id => @sprint_state_id }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
                @res = JSON.parse(last_response.body)
                @sql = @mysql_client.query("select * from contributors ORDER BY ID DESC").first
            end
            context "contributor" do
                it "should include repo name" do
                    expect(@sql["repo"]).to_not be nil
                end
                it "should include user_id" do
                    expect(@sql["user_id"]).to eq(users(:adam_confirmed).id)
                end
                it "should include sprint_state_id" do
                    expect(@sql["sprint_state_id"]).to eq(@sprint_state_id)
                end
            end
            it "should return contributor id" do
                expect(@res["id"]).to eq(@sql["id"])
            end
            context "repo" do
                before(:each) do
                    @git = %x(cd #{@uri}; git branch)
                end
                it "should create master branch" do
                    expect(@git).to include("master")
                end
                it "should create sprint_state branch" do
                    expect(@git).to include(@sprint_state_id.to_s)
                end
            end
        end 
        context "invalid sprint_state_id" do
            fixtures :users, :projects
            before(:each) do
                @project = projects(:demo).id
                @sprint_state_id = 99
                post "/projects/#{@project}/contributors", {:sprint_state_id => @sprint_state_id }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
                @res = JSON.parse(last_response.body)
            end
            it "should return nil" do
                expect(@res["message"]).to_not be nil
            end
        end
        context "sprint_state_id with contributor = false" do
            fixtures :users, :sprint_states, :states,  :projects
            before(:each) do
                @sprint_state_id = sprint_states(:sprint_1_no_contributors).id
                @project = projects(:demo).id
                post "/projects/#{@project}/contributors", {:sprint_state_id => @sprint_state_id }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
                @res = JSON.parse(last_response.body)
            end
            it "should return not return contributor id" do
                expect(@res.keys).to_not include("id")
            end
            it "should return error message" do
                expect(@res["message"]).to eq("We are not accepting contributions at this time")
            end
        end
    end
    describe "GET /projects/:id/contributors/:contributor_id" do
        fixtures :projects, :sprints, :sprint_states, :contributors
        before(:each) do
            @project = projects(:demo).id
        end
        context "valid contributor" do
            before(:each) do
                get "/projects/#{@project}/contributors/#{contributors(:adam_confirmed_1).id}", {}, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                @sql = @mysql_client.query("select * from contributors ORDER BY ID DESC").first
                @res = JSON.parse(last_response.body)
            end
            it "should return contributor id" do
                expect(@res["id"]).to eq(@sql["id"])
            end
        end

    end
    describe "PATCH /projects/:id/contributors/:contributor_id" do
        fixtures :projects, :sprints, :sprint_states, :contributors
        before(:each) do
            Octokit::Client.any_instance.stub(:login) { @username }
            Octokit::Client.any_instance.stub(:create_repository) { {} }

            body = {
                :name=>"1",
                :commit=>{
                    :sha=>sprint_states(:sprint_1_state_1).sha
                }
            }

            @body = JSON.parse(body.to_json, object_class: OpenStruct)
            Octokit::Client.any_instance.stub(:branch => @body)
        end
        context "valid contributor" do
            fixtures :users, :sprint_states, :projects, :contributors
            before(:each) do
                @sprint_state_id = contributors(:adam_confirmed_1).sprint_state_id
                @project = projects(:demo).id

                %x( cd #{@uri}; git checkout -b #{@sprint_state_id}; git add .; git commit -m"new branch"; git branch)
                patch "/projects/#{@project}/contributors/#{contributors(:adam_confirmed_1).id}", {}, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
                @res = JSON.parse(last_response.body)
                @sql = @mysql_client.query("select * from contributors ORDER BY ID DESC").first
            end
            context "contributor" do
                it "should include commit" do
                    expect(@sql["commit"]).to eq(@sha)
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
            fixtures :users, :projects
            before(:each) do
                @project = projects(:demo).id
                @sprint_state_id = 99
                patch "/projects/#{@project}/contributors/33", {}, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
                @res = JSON.parse(last_response.body)
            end
            it "should return nil" do
                expect(@res["message"]).to_not be nil
            end
        end
    end
    describe "POST /contributors/:id/comments" do
        fixtures :projects, :sprints, :sprint_states, :contributors
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
        end
        context "invalid comment" do
            it "should return error message" do
                post "/contributors/#{@contributor_id}/comments", {:text => "A", :sprint_state_id => @sprint_state_id}.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
                res = JSON.parse(last_response.body)
                expect(res["message"]).to eq("Please enter a more detailed comment")
            end
        end
    end
    describe "POST /contributors/:id/votes" do
        fixtures :projects, :sprints, :sprint_states, :contributors
        before(:each) do
            @sprint_state_id = contributors(:adam_confirmed_1).sprint_state_id
            @contributor_id = contributors(:adam_confirmed_1).id
            @project = projects(:demo).id
            post "/contributors/#{@contributor_id}/votes", {:sprint_state_id => @sprint_state_id}.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
            @res = JSON.parse(last_response.body)
            @mysql = @mysql_client.query("select * from votes").first
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
    describe "POST /contributors/:id/winner" do
        fixtures :users, :projects, :sprints, :sprint_states, :contributors
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
            context "sprint_timeline" do
                it "should save sprint_state_id" do
                    expect(@timeline["sprint_state_id"]).to eq(@sprint_state_id)
                end
            end
        end
    end
    describe "POST /contributors/:id/merge" do
        fixtures :users, :projects, :sprints, :sprint_states, :contributors
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

    shared_examples_for "sprint_skillsets" do
        context "all" do
            it "should return all skillsets" do
                expect(@res.length).to eq(Skillset.count)
                Skillset.all.each_with_index do |skillset,i|
                    expect(@res[i]["name"]).to eq(skillset.name)
                end
            end
        end
        context "sprint skillsets" do
            it "should include active" do
                @res.each do |skillset| 
                    if SprintSkillset.count > 0
                        if skillset["id"] == sprint_skillsets(:sprint_1_skillset_1).id
                            expect(skillset["active"]).to eq(sprint_skillsets(:sprint_1_skillset_1).active)
                        end
                    end
                end
            end
        end
    end

    describe "GET /sprints/:sprint_id/skillsets" do
        fixtures :skillsets, :sprints
        before(:each) do
            @sprint_id = sprints(:sprint_1).id
        end
        context "no sprint_skillsets" do
            before(:each) do
                get "/sprints/#{@sprint_id}/skillsets", {},  {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"} 
                @res = JSON.parse(last_response.body)
            end
            it_behaves_like "sprint_skillsets"
        end
        context "sprint_skillsets" do
            fixtures :sprint_skillsets
            before(:each) do
                get "/sprints/#{@sprint_id}/skillsets", {},  {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}  
                @res = JSON.parse(last_response.body)
            end 
            it_behaves_like "sprint_skillsets"
        end

    end

    describe "GET /sprints/:sprint_id/skillsets/:skillset_id" do
        fixtures :skillsets, :sprints
        before(:each) do
            @sprint_id = sprints(:sprint_1).id
            @skillset_id = skillsets(:skillset_1).id
        end
        context "no sprint_skillsets" do
            before(:each) do
                get "/sprints/#{@sprint_id}/skillsets/#{@skillset_id}", {},  {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
                @res = [JSON.parse(last_response.body)]
            end
            it_behaves_like "sprint_skillsets"
        end
        context "sprint_skillsets" do
            fixtures :sprint_skillsets
            before(:each) do
                get "/sprints/#{@sprint_id}/skillsets/#{@skillset_id}", {},  {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
                @res = [JSON.parse(last_response.body)]
            end
            it_behaves_like "sprint_skillsets"
        end
    end

    shared_examples_for "sprint_skillset_update" do
        context "response" do
            it "should return skillset_id as id" do
                expect(@res["id"]).to eq(@skillset_id)
            end
        end
        context "sprint_skillset" do
            it "should include most recent active" do
                expect(@mysql["active"]).to eq(@active ? 1 : 0)
            end
        end
    end

    describe "PATCH /skillsets" do
        fixtures :skillsets, :sprints
        before(:each) do
            @sprint_id = sprints(:sprint_1).id
            @skillset_id = skillsets(:skillset_1).id 
        end
        context "admin" do
            context "skillset exists" do
                fixtures :sprint_skillsets
                before(:each) do
                    @active = false 
                    patch "/sprints/#{@sprint_id}/skillsets/#{@skillset_id}", {:active => @active}.to_json,  {"HTTP_AUTHORIZATION" => "Bearer #{@admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
                    @res = JSON.parse(last_response.body)
                    @mysql = @mysql_client.query("select * from sprint_skillsets where id = #{sprint_skillsets(:sprint_1_skillset_1).id}").first
                end
                it_behaves_like "sprint_skillset_update"
            end 
            context "skillset does not exist" do
                before(:each) do
                    @active = true
                    patch "/sprints/#{@sprint_id}/skillsets/#{@skillset_id}", {:active => @active}.to_json,  {"HTTP_AUTHORIZATION" => "Bearer #{@admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
                    @res = JSON.parse(last_response.body)
                    @mysql = @mysql_client.query("select * from sprint_skillsets").first
                end
                it_behaves_like "sprint_skillset_update"
            end
        end
        context "non-admin" do
            before(:each) do
                @active = false
                patch "/sprints/#{@sprint_id}/skillsets/#{@skillset_id}", {:active => @active}.to_json,  {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
                @res = JSON.parse(last_response.body)
            end
            it "should return 401" do
                expect(last_response.status).to eq(401) 
            end
        end
    end

    shared_examples_for "user_skillsets" do
        context "all" do
            it "should return all skillsets" do
                expect(@res.length).to eq(Skillset.count)
                Skillset.all.each_with_index do |skillset,i|
                    expect(@res[i]["name"]).to eq(skillset.name)
                end
            end
        end
        context "user skillsets" do
            it "should include active" do
                @res.each do |skillset| 
                    if UserSkillset.count > 0
                        if skillset["id"] == user_skillsets(:user_1_skillset_1).id
                            expect(skillset["active"]).to eq(user_skillsets(:user_1_skillset_1).active)
                        end
                    end
                end
            end
        end
    end

    describe "GET /account/:user_id/skillsets" do
        fixtures :skillsets, :users
        before(:each) do
            @user_id = users(:adam).id
        end
        context "no user_skillsets" do
            before(:each) do
                get "/account/#{@user_id}/skillsets", {},  {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"} 
                @res = JSON.parse(last_response.body)
            end
            it_behaves_like "user_skillsets"
        end
        context "user_skillsets" do
            fixtures :user_skillsets
            before(:each) do
                get "/account/#{@user_id}/skillsets", {},  {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}  
                @res = JSON.parse(last_response.body)
            end 
            it_behaves_like "user_skillsets"
        end

    end

    describe "GET /account/:user_id/skillsets/:skillset_id" do
        fixtures :skillsets, :users
        before(:each) do
            @user_id = users(:adam).id
            @skillset_id = skillsets(:skillset_1).id
        end
        context "no user_skillsets" do
            before(:each) do
                get "/account/#{@user_id}/skillsets/#{@skillset_id}", {},  {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
                @res = [JSON.parse(last_response.body)]
            end
            it_behaves_like "user_skillsets"
        end
        context "user_skillsets" do
            fixtures :user_skillsets
            before(:each) do
                get "/account/#{@user_id}/skillsets/#{@skillset_id}", {},  {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
                @res = [JSON.parse(last_response.body)]
            end
            it_behaves_like "user_skillsets"
        end
    end

    shared_examples_for "user_skillset_update" do
        context "response" do
            it "should return skillset_id as id" do
                expect(@res["id"]).to eq(@skillset_id)
            end
        end
        context "user_skillset" do
            it "should include most recent active" do
                expect(@mysql["active"]).to eq(@active ? 1 : 0)
            end
        end
    end

    describe "PATCH user_id/skillsets" do
        fixtures :skillsets, :users
        before(:each) do
            @user_id = users(:adam_confirmed).id
            @skillset_id = skillsets(:skillset_1).id 
        end
        context "admin" do
            context "skillset exists" do
                before(:each) do
                    @active = false
                    patch "/account/#{@user_id}/skillsets/#{@skillset_id}", {:active => @active}.to_json,  {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
                    @res = JSON.parse(last_response.body)
                    @mysql = @mysql_client.query("select * from user_skillsets").first
                end
                it_behaves_like "user_skillset_update"
            end 
            context "skillset does not exist" do
                before(:each) do
                    @active = true
                    patch "/account/#{@user_id}/skillsets/#{@skillset_id}", {:active => @active}.to_json,  {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
                    @res = JSON.parse(last_response.body)
                    @mysql = @mysql_client.query("select * from user_skillsets").first
                end
                it_behaves_like "user_skillset_update"
            end
        end
        context "non-authorized" do
            before(:each) do
                @active = false
                patch "/account/#{users(:adam).id}/skillsets/#{@skillset_id}", {:active => @active}.to_json,  {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
                puts @res = JSON.parse(last_response.body)
            end
            it "should return 401" do
                expect(last_response.status).to eq(401) 
            end
        end
        context "lost 'active' key" do
            before(:each) do
                @active = false
                patch "/account/#{@user_id}/skillsets/#{@skillset_id}", {:activ => @active}.to_json,  {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
                puts @res = JSON.parse(last_response.body)
            end
            it "should return 400" do
                expect(last_response.status).to eq(400) 
            end
        end
    end 

    shared_examples_for "user_roles" do
        context "all" do
            it "should return all roles" do
                expect(@res.length).to eq(Role.count)
                Role.all.each_with_index do |role,i|
                    expect(@res[i]["name"]).to eq(role.name)
                end
            end
        end
        context "user roles" do
            it "should include active" do
                @res.each do |role| 
                    if UserRole.count > 0
                        expect(role.with_indifferent_access).to have_key(:active)
                    end
                end
            end
        end
    end

    describe "GET /account/:user_id/roles" do
        fixtures :roles, :users
        before(:each) do
            @user_id = users(:adam).id
        end
        context "user_roles" do
            fixtures :user_roles
            before(:each) do
                get "/account/#{@user_id}/roles", {},  {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}  
                @res = JSON.parse(last_response.body)
            end 
            it_behaves_like "user_roles"
        end
    end

    shared_examples_for "user_role" do
        context "by id" do
            it "should return role" do
                mysql = Role.find_by(id: @role_id)
                expect(@res["name"]).to eq(mysql["name"])
            end
        end
        context "user roles" do
            it "should include active" do
                if UserRole.count > 0
                    expect(@res.with_indifferent_access).to have_key(:active)
                end
            end
        end
    end

    describe "GET /account/:user_id/roles/:role_id" do
        fixtures :roles, :users
        before(:each) do
            @user_id = users(:adam).id
            @role_id = roles(:product).id
        end
        context "user_roles" do
            fixtures :user_roles
            before(:each) do
                get "/account/#{@user_id}/roles/#{@role_id}", {},  {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
                @res = [JSON.parse(last_response.body)][0][0]
            end
            it_behaves_like "user_role"
        end
    end

    shared_examples_for "user_role_update" do
        context "response" do
            it "should return role_id as id" do
                expect(@res["id"]).to eq(@role_id)
            end
        end
        context "user_role" do
            it "should include most recent active" do
                expect(@mysql["active"]).to eq(@active ? 1 : 0)
            end
        end
    end

    describe "PATCH user_id/roles" do
        fixtures :roles, :users
        before(:each) do
            @user_id = users(:adam_confirmed).id
            @role_id = roles(:product).id 
        end
        context "authorized" do
            context "role exists" do
                before(:each) do
                    @active = false
                    patch "/account/#{@user_id}/roles/#{@role_id}", {:active => @active}.to_json,  {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
                    @res = JSON.parse(last_response.body)
                    @mysql = @mysql_client.query("select * from user_roles").first
                end
                it_behaves_like "user_role_update"
            end
        end
        context "non-authorized" do
            before(:each) do
                @active = false
                patch "/account/#{users(:adam).id}/roles/#{@role_id}", {:active => @active}.to_json,  {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
                @res = JSON.parse(last_response.body)
            end
            it "should return 401" do
                expect(last_response.status).to eq(401) 
            end
        end
    end
end


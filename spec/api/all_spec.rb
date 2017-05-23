require_relative '../spec_helper'
require_relative '../api_spec_helper'

describe "tests that need to be refactored / split" do

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


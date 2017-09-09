require 'spec_helper'
require 'api_helper'

describe "/users" do

    fixtures :users, :seats
    before(:all) do
        @CREATE_TOKENS=true
        @per_page = 10
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

    shared_examples_for "profile" do
        it "should return created_at" do
            expect(@res["created_at"]).to_not be nil
        end
        it "should return industry" do
            expect(@res["industry"]).to eq @position.industry
        end 
        it "should return location" do
            expect(@res["location"]).to eq @profile.location_name
        end                         
        it "should return size" do
            expect(@res["size"]).to eq @position.size
        end                                     
        it "should return title" do
            expect(@res["title"]).to eq @position.title
        end  
    end

    describe "GET /:id" do
        context "with linkedin" do
            fixtures :user_profiles, :user_positions
            before(:each) do
                @user_id = users(:adam_confirmed).id
                @position = user_positions(:adam_confirmed)
                @profile = user_profiles(:adam_confirmed)
            end
            context "user exists" do
                before(:each) do
                    get "/users/#{@user_id}", {}, {}
                    @res = JSON.parse(last_response.body)
                end
                it_behaves_like "profile"
            end
            context "invalid user" do
                before(:each) do
                    get "/users/930", {}, {}
                    it_behaves_like "not_found"
                end                                             
            end
        end
        context "without linkedin" do
            context "user exists" do
                before(:each) do
                    @user_id = users(:adam_confirmed).id
                    get "/users/#{@user_id}", {}, {}
                    @res = JSON.parse(last_response.body)
                end
                it "should return id" do
                    expect(@res["id"]).to eq(@user_id)
                end
            end
        end
    end

    describe "GET /me" do
        fixtures :user_profiles, :user_positions
        context "signed in", :focus => true do
            before(:each) do
                @position = user_positions(:adam_confirmed)
                @profile = user_profiles(:adam_confirmed)
                get "/users/me", {}, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"} 
                follow_redirect!
                @res = JSON.parse(last_response.body)
            end 
            it_behaves_like "profile"
        end
    end

    describe "GET /:user_id/skillsets" do
        fixtures :skillsets
        before(:each) do
            @user_id = users(:adam).id
        end
        context "no user_skillsets" do
            before(:each) do
                get "/users/#{@user_id}/skillsets", {},  {}
                @res = JSON.parse(last_response.body)
            end
            it_behaves_like "user_skillsets"
        end
        context "user_skillsets" do
            fixtures :user_skillsets
            before(:each) do
                get "/users/#{@user_id}/skillsets", {},  {}
                @res = JSON.parse(last_response.body)
            end 
            it_behaves_like "user_skillsets"
        end
    end

    describe "GET /me/skillsets" do
        fixtures :skillsets
        before(:each) do
            @user_id = users(:adam).id
        end
        context "user_skillsets" do
            fixtures :user_skillsets
            before(:each) do
                get "/users/me/skillsets", {},  {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                follow_redirect!
                @res = JSON.parse(last_response.body)
            end
            it_behaves_like "user_skillsets"
        end
    end

    describe "GET /me/skillsets/:skillset_id" do
        fixtures :skillsets
        before(:each) do
            @user_id = users(:adam).id
            @skillset_id = skillsets(:skillset_1).id
        end
        context "no user_skillsets" do
            before(:each) do
                get "/users/me/skillsets/#{@skillset_id}", {}, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"} 
                @res = [JSON.parse(last_response.body)]
            end
            it_behaves_like "user_skillsets"
        end
        context "user_skillsets" do
            fixtures :user_skillsets
            before(:each) do
                get "/users/me/skillsets/#{@skillset_id}", {}, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"} 
                @res = [JSON.parse(last_response.body)]
            end
            it_behaves_like "user_skillsets"
        end
        context "signed out" do
            before(:each) do
                get "/users/me/skillsets/2"
            end
            it_behaves_like "unauthorized"
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

    describe "PATCH /me/skillsets" do
        fixtures :skillsets
        before(:each) do
            @user_id = users(:adam_confirmed).id
            @skillset_id = skillsets(:skillset_1).id 
        end
        context "owner" do
            context "skillset exists" do
                before(:each) do
                    @active = false
                    patch "/users/me/skillsets/#{@skillset_id}", {:active => @active}.to_json,  {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                    @res = JSON.parse(last_response.body)
                    @mysql = @mysql_client.query("select * from user_skillsets").first
                end
                it_behaves_like "user_skillset_update"
                it_behaves_like "ok"
            end 
            context "skillset does not exist" do
                before(:each) do
                    @active = true
                    patch "/users/me/skillsets/#{@skillset_id}", {:active => @active}.to_json,  {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                    @res = JSON.parse(last_response.body)
                    @mysql = @mysql_client.query("select * from user_skillsets").first
                end
                it_behaves_like "user_skillset_update"
                it_behaves_like "ok"
            end
        end
        context "lost 'active' key" do
            before(:each) do
                @active = false
                patch "/users/me/skillsets/#{@skillset_id}", {:activ => @active}.to_json,  {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
            end
            it_behaves_like "error", "missing active field"
        end
    end 

    shared_examples_for "user_roles" do
        context "all" do
            it "should return all roles" do
                expect(@res.length).to eq(Role.count)
                Role.all.order(:name).each_with_index do |role,i|
                    expect(@res[i]["name"]).to eq(role.name)
                    expect(@res[i]["fa_icon"]).to eq(role.fa_icon)
                end
            end
            it "should return role description" do
                Role.all.order(:name).each_with_index do |role,i|
                    expect(@res[i]["description"]).to eq(role.description)
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

    describe "GET /:user_id/roles" do
        fixtures :roles
        before(:each) do
            @user_id = users(:adam).id
        end
        context "user_roles" do
            fixtures :user_roles
            before(:each) do
                get "/users/#{@user_id}/roles", {}, {}
                @res = JSON.parse(last_response.body)
            end 
            it_behaves_like "user_roles"
            it_behaves_like "ok"
        end
    end

    describe "GET /me/roles" do
        fixtures :roles
        before(:each) do
            @user_id = users(:adam).id
        end
        context "user_roles" do
            fixtures :user_roles
            before(:each) do
                get "/users/me/roles", {},  {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                follow_redirect!
                @res = JSON.parse(last_response.body)
            end
            it_behaves_like "user_roles"
            it_behaves_like "ok"
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

    describe "GET /me/roles/:role_id" do
        fixtures :roles
        before(:each) do
            @user_id = users(:adam).id
            @role_id = roles(:product).id
        end
        context "user_roles" do
            fixtures :user_roles
            before(:each) do
                get "/users/me/roles/#{@role_id}", {}, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                @res = JSON.parse(last_response.body)
            end
            it_behaves_like "user_role"
            it_behaves_like "ok"
        end
        context "signed out" do
            before(:each) do
                get "/users/me/roles/2"
            end
            it_behaves_like "unauthorized" 
        end 
    end

    shared_examples_for "user_role_update" do
        context "response" do
            it "should return id" do
                expect(@res["id"]).to eq(@mysql["role_id"])
            end
        end
        context "user_role" do
            it "should include most recent active" do
                expect(@mysql["active"]).to eq(@active ? 1 : 0)
            end
        end
    end

    describe "PATCH /me/roles" do
        fixtures :roles
        before(:each) do
            @user_id = users(:adam_confirmed).id
            @role_id = roles(:product).id 
        end
        context "owner" do
            context "role exists" do
                before(:each) do
                    @active = false
                    patch "/users/me/roles/#{@role_id}", {:active => @active}.to_json,  {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                    @res = JSON.parse(last_response.body)
                    @mysql = @mysql_client.query("select * from user_roles").first
                end
                it_behaves_like "user_role_update"
                it_behaves_like "ok"
            end
        end
    end

    shared_examples_for "contact_info" do
        it "should include user_name" do
            @contact_result.each_with_index do |r,i|
                expect(@res[i]["first_name"]).to eq(r["first_name"])
            end
        end
        it "should include email" do
            @contact_result.each_with_index do |r,i|
                expect(@res[i]["email"]).to eq(r["email"])
            end
        end
    end

    shared_examples_for "contact_team" do
        it "should include team_id" do
            @contact_result.each_with_index do |r,i|
                expect(@res[i]["team_id"]).to eq(r["team_id"])               
                expect(r["team_id"]).to eq(@team_id)
                expect(r["confirmed"]).to eq(@confirmed)
                expect(r["read"]).to eq(@read)
            end
        end
    end

    shared_examples_for "contact" do
        it "should include user_id" do
            @contact_result.each_with_index do |r,i|
                expect(decrypt(@res[i]["user_id"]).to_i).to eq(r["user_id"])
            end
        end
        it "should include contact_id" do
            @contact_result.each_with_index do |r,i|
                expect(decrypt(@res[i]["contact_id"]).to_i).to eq(r["contact_id"])
            end
        end
        it "should include read" do
            @contact_result.each_with_index do |r,i|
                expect(@res[i]["read"]).to eq(r["read"] == 1)
            end
        end
        it "should include confirmed" do
            @contact_result.each_with_index do |r,i|
                expect(@res[i]["confirmed"]).to eq(r["confirmed"])
            end
        end
        it "should include created_at" do
            @contact_result.each_with_index do |r,i|
                expect(@res[i]["created_at"]).to_not be nil
            end
        end
        it "should include updated_at" do
            @contact_result.each_with_index do |r,i|
                expect(@res[i]["updated_at"]).to_not be nil 
            end
        end
    end

    describe "GET /me/connections" do
        fixtures :user_connections
        context "signed in" do
            before(:each) do
                get "/users/me/connections", {},  {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                @res = JSON.parse(last_response.body)
                @contact_result = @mysql_client.query("(select user_connections.*, users.first_name, users.email from user_connections inner join users ON user_connections.contact_id=users.id AND user_connections.user_id = #{decrypt(user_connections(:adam_confirmed_request_adam_accepted).user_id).to_i} left join user_teams ut on user_connections.contact_id = ut.user_id where user_connections.confirmed=2 and user_connections.team_id is null or ut.seat_id = #{seats(:priority).id}) UNION (select user_connections.*, users.first_name, users.email from user_connections inner join users ON user_connections.user_id=users.id AND user_connections.contact_id = #{decrypt(user_connections(:adam_confirmed_request_adam_accepted).user_id).to_i} left join user_teams ut on user_connections.contact_id = ut.user_id where user_connections.team_id is null or ut.seat_id = #{seats(:priority).id})")
            end
            it_behaves_like "contact"
            it_behaves_like "contact_info"
            it_behaves_like "ok"
        end
        context "not signed in" do
            before(:each) do
                get "/users/me/connections"
            end
            it_behaves_like "unauthorized"
        end
        context "contact belongs to team" do
            fixtures :user_teams, :seats
            context "with sponsored seat" do\
                before(:each) do
                    get "/users/me/connections", {},  {"HTTP_AUTHORIZATION" => "Bearer #{@admin_w7_token}"}
                    @res = JSON.parse(last_response.body)
                    @contact_result = @mysql_client.query("SELECT user_connections.*, user_teams.sender_id, users.first_name, users.email FROM user_teams inner join users on user_teams.sender_id = users.id inner join user_connections on user_teams.user_id = user_connections.contact_id WHERE user_connections.user_id != user_teams.sender_id and user_connections.user_id = #{decrypt(user_connections(:elina_dteam_sponsored).user_id).to_i} and user_connections.team_id is not null and user_teams.seat_id = #{seats(:sponsored).id} and user_connections.confirmed = 2")
                    @inviter_id = user_teams(:elina_dteam_sponsored).sender_id
                end

                it "should include sender_id" do
                    @contact_result.each_with_index do |r, i|
                        expect(decrypt(@res[i]["sender_id"]).to_i).to eq(r["sender_id"])
                        expect(@res[i]["sender_id"]).to eq(@inviter_id)
                    end
                end
            end
            context "with priority seat" do
                before(:each) do
                    get "/users/me/connections", {},  {"HTTP_AUTHORIZATION" => "Bearer #{@admin_w7_token}"}
                    @res = JSON.parse(last_response.body) 
                    @contact_result = @mysql_client.query("(SELECT user_connections.*, users.first_name, users.email FROM user_connections inner join users ON user_connections.contact_id=users.id AND user_connections.user_id = #{decrypt(user_connections(:elina_bteam_priority).user_id).to_i} AND user_connections.confirmed=2 left join user_teams ut ON user_connections.contact_id = ut.user_id WHERE (user_connections.team_id is null or ut.seat_id = #{seats(:priority).id})) UNION (select user_connections.*, users.first_name, users.email FROM user_connections inner join users ON user_connections.user_id=users.id AND user_connections.contact_id = #{decrypt(user_connections(:elina_bteam_priority).user_id).to_i} left join user_teams ut on user_connections.contact_id = ut.user_id where (user_connections.team_id is null or ut.seat_id = #{seats(:priority).id}))")
                end
                it_behaves_like "contact"
                it_behaves_like "contact_info"
                it_behaves_like "ok"
            end
        end
    end

    describe "GET /requests/me" do
        fixtures :user_connections
        context "signed in" do
            before(:each) do
                get "/users/me/requests", {},  {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                @res = JSON.parse(last_response.body)
                @contact_result = @mysql_client.query("select user_connections.*,users.first_name from user_connections inner join users ON user_connections.user_id=users.id where contact_id = #{decrypt(user_connections(:adam_confirmed_request_adam_admin_pending).contact_id).to_i}")
            end
            it_behaves_like "contact"
            it_behaves_like "contact_info" 
            it_behaves_like "ok"
        end
        context "not signed in" do
            before(:each) do
                get "/users/me/requests"
            end
            it_behaves_like "unauthorized"
        end
    end

    describe "GET /me/connections/:id" do
        fixtures :user_connections
        context "signed in" do
            before(:each) do
                get "/users/me/connections/#{user_connections(:adam_confirmed_request_adam_admin_pending).id}", {},  {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                @res = [JSON.parse(last_response.body)]
                @contact_result = @mysql_client.query("select user_connections.*,users.first_name from user_connections inner join users on users.id = user_connections.user_id where contact_id = #{decrypt(user_connections(:adam_confirmed_request_adam_admin_pending).contact_id).to_i} AND user_connections.id = #{user_connections(:adam_confirmed_request_adam_admin_pending).id}")
            end
            it_behaves_like "contact"
            it_behaves_like "contact_info" 
            it_behaves_like "ok"
        end
        context "not signed in" do
            before(:each) do
                get "/users/me/connections/#{user_connections(:adam_confirmed_request_adam_admin_pending).id}"
            end
            it_behaves_like "unauthorized"
        end
    end

    describe "PATCH /me/connections/:id" do
        fixtures :user_connections
        context "signed in" do
            before(:each) do
                @confirmed = 2
                patch "/users/me/connections/#{user_connections(:adam_confirmed_request_adam_admin_pending).id}", {:user_id => user_connections(:adam_confirmed_request_adam_admin_pending).user_id, :read => true, :confirmed => 2}.to_json,  {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                @res = [JSON.parse(last_response.body)]
                @contact_result = @mysql_client.query("select user_connections.*,users.first_name from user_connections inner join users on users.id = user_connections.contact_id where contact_id = #{decrypt(user_connections(:adam_confirmed_request_adam_admin_pending).contact_id).to_i} AND user_connections.id = #{user_connections(:adam_confirmed_request_adam_admin_pending).id}")
            end
            it_behaves_like "contact" 
            it_behaves_like "ok"
            it "should update confirmed" do
                expect(@res[0]["confirmed"]).to eq @confirmed
            end
        end
        context "not signed in" do
            before(:each) do
                patch "/users/me/connections/#{user_connections(:adam_confirmed_request_adam_admin_pending).id}"
            end
            it_behaves_like "unauthorized"
        end
    end

    describe "POST /:id/requests" do
        fixtures :users
        context "signed in" do
            before(:each) do
                post "/users/#{users(:adam_admin).id}/requests", {}, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                @res = [JSON.parse(last_response.body)]
                @contact_result = @mysql_client.query("select * from user_connections where user_id = #{decrypt(users(:adam_admin).id).to_i}")
            end
            it_behaves_like "contact"
            it_behaves_like "created"
        end
        context "not signed in" do
            before(:each) do
                post "/users/#{users(:adam_admin).id}/requests"
            end
            it_behaves_like "unauthorized"
        end
        context "contact belongs to team" do
            fixtures :users, :user_teams, :teams, :seats
            context "with sponsored seat" do
                before(:each) do
                    post "/users/#{users(:elina_bteam_priority).id}/requests", {}, {"HTTP_AUTHORIZATION" => "Bearer #{@admin_w7_token}"}
                    @res = [JSON.parse(last_response.body)]
                    @contact_result = @mysql_client.query("select * from user_connections where contact_id = #{decrypt(users(:elina_bteam_priority).id).to_i}")
                    @team_id = teams(:bteam).id
                    @confirmed = 1
                    @read = 0
                end 
                it_behaves_like "contact"
                it_behaves_like "created"
                it_behaves_like "contact_team"
            end
            context "with sponsored seat" do
                before(:each) do
                    post "/users/#{users(:elina_dteam_sponsored).id}/requests", {}, {"HTTP_AUTHORIZATION" => "Bearer #{@admin_w7_token}"}
                    @res = [JSON.parse(last_response.body)]
                    @contact_result = @mysql_client.query("select * from user_connections where contact_id = #{decrypt(users(:elina_dteam_sponsored).id).to_i}")
                    @team_id = teams(:dteam).id
                    @confirmed = 2
                    @read = 1
                end 
                it_behaves_like "contact"
                it_behaves_like "created"
                it_behaves_like "contact_team"
            end
        end
    end

    describe "GET /:id/requests" do
        fixtures :user_connections
        context "signed in" do
            context "existing" do
                before(:each) do
                    get "/users/#{user_connections(:adam_confirmed_request_adam_admin_pending).contact_id}/requests", {}, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                    @res = [JSON.parse(last_response.body)]
                    @contact_result = @mysql_client.query("select * from user_connections where contact_id = #{decrypt(user_connections(:adam_confirmed_request_adam_admin_pending).contact_id)} AND user_id = #{decrypt(@user).to_i}")
                end
                it_behaves_like "contact"
                it_behaves_like "ok"
            end
            context "not existing" do
                before(:each) do
                    get "/users/222/requests", {}, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                    @res = JSON.parse(last_response.body) 
                end
                it "should return empty" do
                    expect(@res["id"]).to eq 0
                end
            end
            context "user already requested you" do
                before(:each) do
                    get "/users/#{user_connections(:adam_confirmed_request_adam_admin_pending).user_id}/requests", {}, {"HTTP_AUTHORIZATION" => "Bearer #{@admin_w7_token}"}
                    @res = [JSON.parse(last_response.body)]
                    @contact_result = @mysql_client.query("select * from user_connections where user_id = #{decrypt(user_connections(:adam_confirmed_request_adam_admin_pending).contact_id).to_i} AND contact_id = #{decrypt(@user).to_i}")
                end
                it_behaves_like "contact"
                it_behaves_like "ok"
            end
        end
        context "not signed in" do
            before(:each) do    
                get "/users/#{user_connections(:adam_confirmed_request_adam_admin_pending).contact_id}/requests" 
            end                                                 
            it_behaves_like "unauthorized"  
        end                                         
    end

    shared_examples_for "user_notifications" do
        it "should return id" do
            @notification_results.each_with_index do |n,i|
                expect(n["id"]).to eq(@res[i]["id"])
            end 
        end
        it "should return team_name" do
            @notification_results.each_with_index do |n,i|
                if@res[i]["job_id"]
                    team_id = @mysql_client.query("select * from jobs where id = #{@res[i]["job_id"]}").first["team_id"]
                    expect(@res[i]["job_team_name"]).to eq(@mysql_client.query("select * from teams where id = #{team_id}").first["name"])
                end
            end
        end
        it "should return job_title" do
            @notification_results.each_with_index do |n,i|
                if@res[i]["job_id"]
                    expect(@res[i]["job_title"]).to eq(@mysql_client.query("select * from jobs where id = #{@res[i]["job_id"]}").first["title"])
                end
            end
        end
        it "should return job_company" do
            @notification_results.each_with_index do |n,i|
                if@res[i]["job_id"]
                    expect(@res[i]["job_company"]).to eq(@mysql_client.query("select teams.company as company from jobs inner join teams on jobs.team_id = teams.id where jobs.id = #{@res[i]["job_id"]}").first["company"])
                end
            end
        end
    end
    shared_examples_for "user_notifications_timeline" do
        it "should return notification" do
            @notification_results.each_with_index do |n,i|
                expect(n["name"]).to eq(@res[i]["notification"]["name"])
            end
        end
    end

    describe "GET /me/notifications" do
        fixtures :sprint_timelines, :user_notifications, :notifications, :jobs, :teams
        context "signed in" do 
            before(:each) do
                get "/users/me/notifications", {},  {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                @res = JSON.parse(last_response.body)["data"]
                base_query = "select sprint_timelines.*, user_notifications.id, notifications.name from sprint_timelines inner join notifications ON notifications.id = sprint_timelines.notification_id join user_notifications ON sprint_timelines.id = user_notifications.sprint_timeline_id AND user_notifications.user_id = #{decrypt(@user).to_i} ORDER BY created_at DESC"
                @notification_results = @mysql_client.query("#{base_query} limit #{@per_page}")
                @notification_count = @mysql_client.query(base_query).count
            end
            it "should return count" do
                expect(JSON.parse(last_response.body)["meta"]["count"]).to eq @notification_count
            end 
            it_behaves_like "user_notifications"
            it_behaves_like "user_notifications_timeline"
            it_behaves_like "ok"
        end
        context "not signed in" do
            before(:each) do
                get "/users/me/notifications"
            end
            it_behaves_like "unauthorized"
        end
        context "paging" do
            before(:each) do
                @page = 2
                get "/users/me/notifications", {},  {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                @res = JSON.parse(last_response.body)["data"]
                base_query = "select sprint_timelines.*, user_notifications.id, notifications.name from sprint_timelines inner join notifications ON notifications.id = sprint_timelines.notification_id join user_notifications ON sprint_timelines.id = user_notifications.sprint_timeline_id AND user_notifications.user_id = #{decrypt(@user).to_i} ORDER BY created_at DESC"
                @notification_results = @mysql_client.query("#{base_query} limit #{@per_page} offset #{(@page - 1) * @per_page}")
                @notification_count = @mysql_client.query(base_query).count
            end
            it "should return count" do
                expect(JSON.parse(last_response.body)["meta"]["count"]).to eq @notification_count
            end
            it_behaves_like "ok"
            it_behaves_like "user_notifications"
            it_behaves_like "user_notifications_timeline"
        end
    end

    describe "GET /me/notifications/:id" do
        fixtures :sprint_timelines, :user_notifications
        context "signed in" do
            before(:each) do
                get "/users/me/notifications/#{user_notifications(:sprint_1_state_1_winner_for_adam_confirmed).id}", {},  {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                @res = [JSON.parse(last_response.body)["data"]]
                @notification_results = @mysql_client.query("select * from user_notifications where user_notifications.id = #{user_notifications(:sprint_1_state_1_winner_for_adam_confirmed).id}")
            end
            it_behaves_like "user_notifications"
            it_behaves_like "ok"
        end
        context "not signed in" do
            before(:each) do
                get "/users/me/notifications/125"
            end
            it_behaves_like "unauthorized"
        end
    end

    describe "PATCH /me/notifications/:id" do
        fixtures :sprint_timelines, :user_notifications
        context "signed in" do
            before(:each) do                
                patch "/users/me/notifications/#{user_notifications(:sprint_1_state_1_winner_for_adam_confirmed).id}", {},  {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                @res = [JSON.parse(last_response.body)["data"]]                         
                @notification_results = @mysql_client.query("select * from user_notifications where user_notifications.id = #{user_notifications(:sprint_1_state_1_winner_for_adam_confirmed).id}")
            end
            it_behaves_like "user_notifications"                                                            
            it_behaves_like "ok"
            it "should set read = true" do
                expect(@res[0]["read"]).to be true
            end
        end                                                         
        context "not signed in" do                                          
            before(:each) do        
                get "/users/me/notifications/125"
            end                                                         
            it_behaves_like "unauthorized"                                          
        end                                                     
    end

    shared_examples_for "user_notifications_settings" do
        context "all" do
            it "should return all notifications" do
                expect(@res.length).to eq(Notification.count)
                Notification.all.each_with_index do |notification,i|
                    expect(@res[i]["name"]).to eq(notification.name)
                end
            end
            it "should return description" do
                Notification.all.each_with_index do |notification,i|
                    expect(@res[i]["description"]).to eq(notification.description)
                end
            end
            it "should not return nil active" do
                Notification.all.each_with_index do |notification,i|
                    expect(@res[i]["active"]).to_not be nil
                end
            end
        end
    end

    shared_examples_for "user_notifications_settings_by_id" do
        context "user notifications settings" do
            it "should include active" do
                @res.each do |notification| 
                    if UserNotificationSetting.count > 0
                        if notification["id"] == user_notification_settings(:user_1_notification_setting_1).id
                            expect(notification["active"]).to eq(user_notification_settings(:user_1_notification_setting_1).active)
                        end
                    end
                end
            end
        end
    end

    describe "GET /me/notifications-settings" do
        fixtures :notifications
        before(:each) do
            @user_id = users(:adam).id
        end
        context "no user_notification_settings" do
            before(:each) do
                get "/users/me/notifications-settings", {}, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                @res = JSON.parse(last_response.body)
            end
            it_behaves_like "user_notifications_settings"
            it_behaves_like "user_notifications_settings_by_id"
        end
        context "user notifications settings" do
            fixtures :user_notification_settings
            before(:each) do
                get "/users/me/notifications-settings", {}, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                @res = JSON.parse(last_response.body)
            end 
            it_behaves_like "user_notifications_settings"
            it_behaves_like "user_notifications_settings_by_id"
        end
    end

    describe "GET /me/notifications-settings/:notification_id" do
        fixtures :notifications
        before(:each) do
            @user_id = users(:adam).id
            @notification_id = notifications(:new).id
        end
        context "no user_notification_settings" do
            before(:each) do
                get "/users/me/notifications-settings/#{@notification_id}", {}, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"} 
                @res = [JSON.parse(last_response.body)]
            end
            it_behaves_like "user_notifications_settings_by_id"
        end
        context "user_notification_settings" do
            fixtures :user_notification_settings
            before(:each) do
                get "/users/me/notifications-settings/#{@notification_id}", {}, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"} 
                @res = [JSON.parse(last_response.body)]
            end
            it_behaves_like "user_notifications_settings_by_id"
        end
        context "signed out" do
            before(:each) do
                get "/users/me/notifications-settings/2"
            end
            it_behaves_like "unauthorized"
        end
    end

    shared_examples_for "user_notifications_settings_update" do
        context "response" do
            it "should return notification_id as id" do
                expect(@res["id"]).to eq(@notification_id)
            end
        end
        context "user_notification_settings" do
            it "should include most recent active" do
                expect(@mysql["active"]).to eq(@active ? 1 : 0)
            end
        end
    end

    describe "PATCH /me/notifications-settings" do
        fixtures :notifications
        before(:each) do
            @user_id = users(:adam_confirmed).id
            @notification_id = notifications(:new).id 
        end
        context "owner" do
            context "notification exists" do
                before(:each) do
                    @active = false
                    patch "/users/me/notifications-settings/#{@notification_id}", {:active => @active}.to_json,  {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                    @res = JSON.parse(last_response.body)
                    @mysql = @mysql_client.query("select * from user_notification_settings").first
                end
                it_behaves_like "user_notifications_settings_update"
                it_behaves_like "ok"
            end 
            context "notification does not exist" do
                before(:each) do
                    @active = true
                    patch "/users/me/notifications-settings/#{@notification_id}", {:active => @active}.to_json,  {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                    @res = JSON.parse(last_response.body)
                    @mysql = @mysql_client.query("select * from user_notification_settings").first
                end
                it_behaves_like "user_notifications_settings_update"
                it_behaves_like "ok"
            end
        end
        context "lost 'active' key" do
            before(:each) do
                @active = false
                patch "/users/me/notifications-settings/#{@notification_id}", {:activ => @active}.to_json,  {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
            end
            it_behaves_like "error", "missing active field"
        end
    end 
end

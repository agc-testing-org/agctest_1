require 'spec_helper'
require 'api_helper'

describe "/users" do

    fixtures :users, :seats
    before(:all) do
        @CREATE_TOKENS=true
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
        fixtures :user_profiles, :user_positions
        before(:each) do
            @user_id = users(:adam_confirmed).id
            @position = user_positions(:adam_confirmed)
            @profile = user_profiles(:adam_confirmed)
        end
        context "user exists" do
            before(:each) do
                get "/users/#{@user_id}", {},  {}
                @res = JSON.parse(last_response.body)
            end
            it_behaves_like "profile"
        end
        context "invalid user" do
            before(:each) do
                get "/users/930", {},  {}
                @res = JSON.parse(last_response.body)
            end                                             
            it "should return no result" do
                expect(@res).to be_empty
            end
        end
    end

    describe "GET /me" do
        fixtures :user_profiles, :user_positions
        context "signed in" do
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

    describe "GET /:user_id/skillsets/:skillset_id" do
        fixtures :skillsets
        before(:each) do
            @user_id = users(:adam).id
            @skillset_id = skillsets(:skillset_1).id
        end
        context "no user_skillsets" do
            before(:each) do
                get "/users/#{@user_id}/skillsets/#{@skillset_id}", {},  {}
                @res = [JSON.parse(last_response.body)]
            end
            it_behaves_like "user_skillsets"
        end
        context "user_skillsets" do
            fixtures :user_skillsets
            before(:each) do
                get "/users/#{@user_id}/skillsets/#{@skillset_id}", {},  {}
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

    describe "PATCH /:user_id/skillsets" do
        fixtures :skillsets
        before(:each) do
            @user_id = users(:adam_confirmed).id
            @skillset_id = skillsets(:skillset_1).id 
        end
        context "admin" do
            context "skillset exists" do
                before(:each) do
                    @active = false
                    patch "/users/#{@user_id}/skillsets/#{@skillset_id}", {:active => @active}.to_json,  {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                    @res = JSON.parse(last_response.body)
                    @mysql = @mysql_client.query("select * from user_skillsets").first
                end
                it_behaves_like "user_skillset_update"
            end 
            context "skillset does not exist" do
                before(:each) do
                    @active = true
                    patch "/users/#{@user_id}/skillsets/#{@skillset_id}", {:active => @active}.to_json,  {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                    @res = JSON.parse(last_response.body)
                    @mysql = @mysql_client.query("select * from user_skillsets").first
                end
                it_behaves_like "user_skillset_update"
            end
        end
        context "non-authorized" do
            before(:each) do
                @active = false
                patch "/users/#{users(:adam).id}/skillsets/#{@skillset_id}", {:active => @active}.to_json,  {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                puts @res = JSON.parse(last_response.body)
            end
            it "should return 401" do
                expect(last_response.status).to eq(401) 
            end
        end
        context "lost 'active' key" do
            before(:each) do
                @active = false
                patch "/users/#{@user_id}/skillsets/#{@skillset_id}", {:activ => @active}.to_json,  {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
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
                Role.all.order(:name).each_with_index do |role,i|
                    expect(@res[i]["name"]).to eq(role.name)
                    expect(@res[i]["fa_icon"]).to eq(role.fa_icon)
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

    describe "GET /:user_id/roles/:role_id" do
        fixtures :roles
        before(:each) do
            @user_id = users(:adam).id
            @role_id = roles(:product).id
        end
        context "user_roles" do
            fixtures :user_roles
            before(:each) do
                get "/users/#{@user_id}/roles/#{@role_id}", {}, {} 
                @res = JSON.parse(last_response.body)
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

    describe "PATCH /:user_id/roles" do
        fixtures :roles
        before(:each) do
            @user_id = users(:adam_confirmed).id
            @role_id = roles(:product).id 
        end
        context "authorized" do
            context "role exists" do
                before(:each) do
                    @active = false
                    patch "/users/#{@user_id}/roles/#{@role_id}", {:active => @active}.to_json,  {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                    @res = JSON.parse(last_response.body)
                    @mysql = @mysql_client.query("select * from user_roles").first
                end
                it_behaves_like "user_role_update"
            end
        end
        context "non-authorized" do
            before(:each) do
                @active = false
                patch "/users/#{users(:adam).id}/roles/#{@role_id}", {:active => @active}.to_json,  {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                @res = JSON.parse(last_response.body)
            end
            it "should return 401" do
                expect(last_response.status).to eq(401) 
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

    shared_examples_for "contact" do
        it "should include user_id" do
            @contact_result.each_with_index do |r,i|
                expect(@res[i]["user_id"]).to eq(r["user_id"])
            end
        end
        it "should include contact_id" do
            @contact_result.each_with_index do |r,i|
                expect(@res[i]["contact_id"]).to eq(r["contact_id"])
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

    describe "GET /connections" do
        fixtures :user_connections
        context "signed in" do
            before(:each) do
                get "/users/connections", {},  {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                @res = JSON.parse(last_response.body)
                @contact_result = @mysql_client.query("(select user_connections.*, users.first_name, users.email from user_connections inner join users ON user_connections.contact_id=users.id AND user_connections.user_id = #{user_connections(:adam_confirmed_request_adam_accepted).user_id} where user_connections.confirmed=2) UNION (select user_connections.*, users.first_name, users.email from user_connections inner join users ON user_connections.user_id=users.id AND user_connections.contact_id = #{user_connections(:adam_confirmed_request_adam_accepted).user_id})")
            end
            it_behaves_like "contact"
            it_behaves_like "contact_info"
        end
        context "not signed in" do
            before(:each) do
                get "/users/connections"
            end
            it_behaves_like "unauthorized" 
        end
    end

    describe "GET /requests" do
        fixtures :user_connections
        context "signed in" do
            before(:each) do
                get "/users/requests", {},  {"HTTP_AUTHORIZATION" => "Bearer #{@admin_w7_token}"}
                @res = JSON.parse(last_response.body)
                @contact_result = @mysql_client.query("select user_connections.*,users.first_name from user_connections inner join users ON user_connections.contact_id=users.id where contact_id = #{user_connections(:adam_confirmed_request_adam_admin_pending).contact_id}")
            end
            it_behaves_like "contact"
            it_behaves_like "contact_info" 
        end
        context "not signed in" do
            before(:each) do
                get "/users/requests"
            end
            it_behaves_like "unauthorized"
        end
    end

    describe "GET /requests/:id" do
        fixtures :user_connections
        context "signed in" do
            before(:each) do
                get "/users/requests/#{user_connections(:adam_confirmed_request_adam_admin_pending).id}", {},  {"HTTP_AUTHORIZATION" => "Bearer #{@admin_w7_token}"}
                @res = [JSON.parse(last_response.body)]
                @contact_result = @mysql_client.query("select user_connections.*,users.first_name from user_connections inner join users on users.id = user_connections.contact_id where contact_id = #{user_connections(:adam_confirmed_request_adam_admin_pending).contact_id} AND user_connections.id = #{user_connections(:adam_confirmed_request_adam_admin_pending).id}")
            end
            it_behaves_like "contact"
            it_behaves_like "contact_info" 
        end
        context "not signed in" do
            before(:each) do
                get "/users/requests/#{user_connections(:adam_confirmed_request_adam_admin_pending).id}"
            end
            it_behaves_like "unauthorized"
        end
    end

    describe "PATCH /requests/:id" do
        fixtures :user_connections
        context "signed in" do
            before(:each) do
                @confirmed = 2
                patch "/users/requests/#{user_connections(:adam_confirmed_request_adam_admin_pending).id}", {:user_id => user_connections(:adam_confirmed_request_adam_admin_pending).user_id, :read => true, :confirmed => 2}.to_json,  {"HTTP_AUTHORIZATION" => "Bearer #{@admin_w7_token}"}
                @res = [JSON.parse(last_response.body)]
                @contact_result = @mysql_client.query("select user_connections.*,users.first_name from user_connections inner join users on users.id = user_connections.contact_id where contact_id = #{user_connections(:adam_confirmed_request_adam_admin_pending).contact_id} AND user_connections.id = #{user_connections(:adam_confirmed_request_adam_admin_pending).id}")
            end
            it_behaves_like "contact" 
            it "should update confirmed" do
                expect(@res[0]["confirmed"]).to eq @confirmed
            end
        end
        context "not signed in" do
            before(:each) do
                patch "/users/requests/#{user_connections(:adam_confirmed_request_adam_admin_pending).id}"
            end
            it_behaves_like "unauthorized"
        end
    end

    describe "POST /:id/requests" do
        context "signed in" do
            before(:each) do
                post "/users/#{users(:adam_admin).id}/requests", {}, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                @res = [JSON.parse(last_response.body)]
                @contact_result = @mysql_client.query("select * from user_connections where user_id = #{users(:adam_admin).id}")
            end
            it_behaves_like "contact"
        end
        context "not signed in" do
            before(:each) do
                post "/users/#{users(:adam_admin).id}/requests"
            end
            it_behaves_like "unauthorized"
        end
    end

    describe "GET /:id/requests" do
        fixtures :user_connections
        context "signed in" do
            before(:each) do
                get "/users/#{user_connections(:adam_confirmed_request_adam_admin_pending).contact_id}/requests", {}, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                @res = [JSON.parse(last_response.body)]
                @contact_result = @mysql_client.query("select * from user_connections where contact_id = #{user_connections(:adam_confirmed_request_adam_admin_pending).contact_id} AND user_id = #{@user}")
            end
            it_behaves_like "contact"
        end
        context "not signed in" do
            before(:each) do    
                get "/users/#{user_connections(:adam_confirmed_request_adam_admin_pending).contact_id}/requests" 
            end                                                 
            it_behaves_like "unauthorized"  
        end                                         
    end
end

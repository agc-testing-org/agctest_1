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
                get "/users/me", {}, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"} 
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
                get "/users/me/skillsets", {},  {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
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
                    patch "/users/#{@user_id}/skillsets/#{@skillset_id}", {:active => @active}.to_json,  {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
                    @res = JSON.parse(last_response.body)
                    @mysql = @mysql_client.query("select * from user_skillsets").first
                end
                it_behaves_like "user_skillset_update"
            end 
            context "skillset does not exist" do
                before(:each) do
                    @active = true
                    patch "/users/#{@user_id}/skillsets/#{@skillset_id}", {:active => @active}.to_json,  {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
                    @res = JSON.parse(last_response.body)
                    @mysql = @mysql_client.query("select * from user_skillsets").first
                end
                it_behaves_like "user_skillset_update"
            end
        end
        context "non-authorized" do
            before(:each) do
                @active = false
                patch "/users/#{users(:adam).id}/skillsets/#{@skillset_id}", {:active => @active}.to_json,  {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
                puts @res = JSON.parse(last_response.body)
            end
            it "should return 401" do
                expect(last_response.status).to eq(401) 
            end
        end
        context "lost 'active' key" do
            before(:each) do
                @active = false
                patch "/users/#{@user_id}/skillsets/#{@skillset_id}", {:activ => @active}.to_json,  {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
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

    describe "GET /me/roles", :focus => true do
        fixtures :roles
        before(:each) do
            @user_id = users(:adam).id
        end
        context "user_roles" do
            fixtures :user_roles
            before(:each) do
                get "/users/me/roles", {},  {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
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
                    patch "/users/#{@user_id}/roles/#{@role_id}", {:active => @active}.to_json,  {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
                    @res = JSON.parse(last_response.body)
                    @mysql = @mysql_client.query("select * from user_roles").first
                end
                it_behaves_like "user_role_update"
            end
        end
        context "non-authorized" do
            before(:each) do
                @active = false
                patch "/users/#{users(:adam).id}/roles/#{@role_id}", {:active => @active}.to_json,  {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
                @res = JSON.parse(last_response.body)
            end
            it "should return 401" do
                expect(last_response.status).to eq(401) 
            end
        end
    end
end


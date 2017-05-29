require 'spec_helper'
require 'api_helper'

describe "/invites" do

    fixtures :users
    before(:all) do
        @CREATE_TOKENS=true
    end

    shared_examples_for "invites_teams" do
        it "should return invite" do
            expect(@res["id"]).to eq(@team_invite_result["id"])
        end
        it "should return accepted = false" do
            expect(@res["accepted"]).to be false
        end 
        it "should return sender_id" do
            expect(@res["sender_id"]).to eq(@team_invite_result["sender_id"])
        end 
    end

    describe "POST /teams" do
        fixtures :users
        context "valid team_id" do 
            fixtures :teams
            before(:each) do
                @team = teams(:ateam).id
                @email = "adam+12345@wired7.com"
                @user_id = users(:adam).id
            end
            context "non-member" do
                before(:each) do
                    post "/invites/teams", { :email => @email, :id => @team }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                end
                it_behaves_like "unauthorized"
            end
            context "member" do
                fixtures :user_teams
                context "with email" do
                    before(:each) do
                        post "/invites/teams", { :email => @email, :id => @team }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                        @res = JSON.parse(last_response.body)
                        @team_invite_result = @mysql_client.query("select * from user_teams where user_email = '#{@email}'").first
                    end
                    it "should return email" do
                        expect(@res["email"]).to eq(@team_invite_result["email"])
                    end
                    it "should return user_id = null" do
                        expect(@res["user_id"]).to eq(@team_invite_result["user_id"]) 
                    end
                    it_behaves_like "invites_teams"
                end 
                context "with user_id" do
                    context "invalid user_id" do
                        before(:each) do
                            post "/invites/teams", { :user_id => 93, :id => @team }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                            @res = JSON.parse(last_response.body)
                            @team_invite_result = @mysql_client.query("select * from user_teams where user_id = 93")
                        end
                        it "should not save the result" do
                            expect(@team_invite_result.count).to eq(0)
                        end
                        it "should return error message" do
                            expect(@res["error"]).to eq("An error has occurred")
                        end
                    end
                    context "valid user_id" do
                        before(:each) do
                            post "/invites/teams", { :user_id => users(:adam_protected).id, :id => @team }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                            @res = JSON.parse(last_response.body)
                            @team_invite_result = @mysql_client.query("select * from user_teams where user_id = #{users(:adam_protected).id}").first
                        end
                        it "should return user_id" do
                            expect(@res["user_id"]).to eq(@team_invite_result["user_id"])
                        end
                        it "should return email = null" do
                            expect(@res["email"]).to be nil
                        end
                        it_behaves_like "invites_teams"
                    end 
                end
            end
        end
        context "invalid team_id" do
            before(:each) do
                post "/invites/teams", { :email => "adam+123@wired7.com", :id => 27 }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
            end
            it_behaves_like "unauthorized"
        end
    end
end

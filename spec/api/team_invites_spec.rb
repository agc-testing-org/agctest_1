require 'spec_helper'
require 'api_helper'

describe "/team-invites" do

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
        it "should not return token" do
            expect(@res.keys).to_not include "token"
        end
        it "should store token" do
            expect(@team_invite_result["token"]).to_not be nil
        end
    end

    describe "POST /" do
        fixtures :users
        context "valid team_id" do 
            fixtures :teams
            before(:each) do
                @team = teams(:ateam).id
                @email = "adam+gets+invited@wired7.com"
                @user_id = users(:adam).id
            end
            context "non-member" do
                before(:each) do
                    post "/team-invites", { :email => @email, :id => @team }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                end
                it_behaves_like "unauthorized"
            end
            context "member" do
                fixtures :user_teams
                context "with email" do
                    before(:each) do
                        post "/team-invites", { :email => @email, :id => @team }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
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
            end
        end
        context "invalid team_id" do
            before(:each) do
                post "/team-invites", { :email => "adam+123@wired7.com", :id => 27 }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
            end
            it_behaves_like "unauthorized"
        end
    end
    describe "GET /:token", :focus => true do
        fixtures :users, :teams, :user_teams
        before(:each) do        
            @invite = user_teams(:adam_invited)
        end
        context "valid token" do
            before(:each) do
                get "/team-invites/#{@invite.token}"
                @res = JSON.parse(last_response.body)
            end
            it "should return invite id" do
                expect(@res["id"]).to eq @invite.id
            end
            it "should return team name" do
                expect(@res["name"]).to eq @invite.team.name
            end
            it "should return email" do
                expect(@res["email"]).to eq @invite.user_email
            end
            it "should return sender name" do
                expect(@res["sender"]).to eq @invite.sender.first_name
            end
        end 
    end
end

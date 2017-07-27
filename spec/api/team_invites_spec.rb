require 'spec_helper'
require 'api_helper'

describe "/team-invites" do

    fixtures :users

    describe "GET /?token=" do
        fixtures :teams, :user_teams
        before(:each) do
            @invite = user_teams(:adam_confirmed_b_team)
        end
        context "valid token" do
            before(:each) do
                get "/team-invites?token=#{@invite.token}"
                @res = JSON.parse(last_response.body)
            end
            it "should return invite id" do
                expect(@res["id"]).to eq @invite.id
            end
            it "should return team name" do
                expect(@res["name"]).to eq @invite.team.name
            end
            it "should return valid" do
                expect(@res["valid"]).to be true
            end
            it "should return expired" do
                expect(@res["expired"]).to be false
            end 
            it_behaves_like "ok"
        end
        context "expired token" do
            before(:each) do
                @invite = user_teams(:adam_invited_expired) 
                get "/team-invites?token=#{@invite.token}"
                @res = JSON.parse(last_response.body)
            end
            it "should return valid" do
                expect(@res["valid"]).to be true
            end 
            it "should return expired" do
                expect(@res["expired"]).to be true 
            end
            it_behaves_like "ok"
        end
        context "invalid token" do
            before(:each) do
                @token = "YYEEA"
                get "/team-invites?token=#{@token}"
                @res = JSON.parse(last_response.body)
            end
            it_behaves_like "ok"
            it "should return valid" do
                expect(@res["valid"]).to be false
            end
        end
    end
    
    describe "POST /shares" do
        before(:all) do
            @CREATE_TOKENS=true
        end
        fixtures :teams, :user_teams
        before(:each) do
            post "/shares", {:token => user_teams(:adam_confirmed_share_2_cteam).token}.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
            @result = @mysql_client.query("select * from user_teams where id = '#{user_teams(:adam_confirmed_share_2_cteam).id}'").first
            @res = JSON.parse(last_response.body)
        end
        it "should return true" do
            expect(@res["valid"]).to be true
        end
        it "should update the invitation" do
            expect(@result["accepted"]).to be 1 
        end
        it "should delete the token" do
            expect(@result["token"]).to be nil
        end
    end
end

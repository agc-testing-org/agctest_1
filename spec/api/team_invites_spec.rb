require 'spec_helper'
#require 'api_helper'

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
end

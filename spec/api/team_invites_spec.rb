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
            it "should return email" do
                expect(@res["sender_email"]).to eq @invite.sender.email
            end
            it "should return sender name" do
                expect(@res["sender_first_name"]).to eq @invite.sender.first_name
            end
            it_behaves_like "ok"
        end
        context "expired token" do
            before(:each) do
                @invite = user_teams(:adam_invited_expired) 
                get "/team-invites?token=#{@invite.token}"
            end
            it_behaves_like "error", "this invitation has expired"
        end
        context "invalid token" do
            before(:each) do
                @token = "YYEEA"
                get "/team-invites?token=#{@token}"
            end
            it_behaves_like "error", "this invitation is invalid"
        end
    end
end

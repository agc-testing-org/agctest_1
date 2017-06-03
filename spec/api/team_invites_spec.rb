require 'spec_helper'
require 'api_helper'

describe "/team-invites" do

    fixtures :users
    before(:all) do
        @CREATE_TOKENS=true
    end

    describe "GET /?token=" do
        fixtures :teams, :user_teams
        before(:each) do
            @invite = user_teams(:adam_invited)
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
                expect(@res["email"]).to eq @invite.user_email
            end
            it "should return sender name" do
                expect(@res["sender"]).to eq @invite.sender.first_name
            end
        end
        context "invalid token" do
            before(:each) do
                get "/team-invites?token=YYEEA"
                @res = JSON.parse(last_response.body)
            end
            it "should return empty" do
                expect(@res).to be_empty
            end
        end
    end
end

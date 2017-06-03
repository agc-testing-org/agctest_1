require 'spec_helper'
require 'api_helper'

describe "/user-teams" do

    fixtures :users
    before(:all) do
        @CREATE_TOKENS=true
    end


    describe "GET /?token=" do
        fixtures :users, :teams, :user_teams
        before(:each) do
            @invite = user_teams(:adam_invited)
        end
        context "valid token" do
            before(:each) do
                get "/user-teams?token=#{@invite.token}"
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

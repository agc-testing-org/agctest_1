require_relative '../spec_helper'

describe ".Organization" do
    fixtures :teams
    before(:each) do
        @team = Organization.new
    end

    context "#invite_member" do
        fixtures :users, :teams, :user_teams, :seats
        before(:each) do
            @new_team = teams(:different_team_for_invite)
        end
        context "not on another team" do
            before(:each) do
                @email = "adam+not+on+another+team@wired7.com"
                @res = @team.invite_member @new_team.id, @new_team[:user_id], nil, @email, seats(:priority).id, nil, nil 
            end
            it "should not return an error" do
                expect(@res.errors.messages).to be_empty
            end
        end
        context "on another team prior to expiration" do
            before(:each) do
                @current_user_team = user_teams(:adam_confirmed_b_team)
                @res = @team.invite_member @new_team.id, @new_team[:user_id], nil, @current_user_team.user_email, seats(:priority).id, nil, nil 
            end 
            it "should return error" do
                expect(@res.errors.messages[:user_email][0]).to eq "this user is exclusively working with another team"
            end
        end
        context "on another team after expiration" do
            before(:each) do
                @current_user_team = user_teams(:adam_confirmed_b_team)
                @mysql_client.query("update user_teams set expires = '#{1.hour.ago.to_s(:db)}' where user_email = '#{@current_user_team.user_email}'")
                @res = @team.invite_member @new_team.id, @new_team[:user_id], nil, @current_user_team.user_email, seats(:priority).id, nil, nil
            end 
            it "should return error" do
                expect(@res.errors.messages).to be_empty 
            end
        end
    end
end

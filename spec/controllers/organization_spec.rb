require_relative '../spec_helper'

describe ".Organization" do
    fixtures :teams
    before(:each) do
        @team = Organization.new
    end
    context "#member?" do
        fixtures :users, :user_teams
        before(:each) do
            @team_id = teams(:ateam).id
        end
        context "is a member" do
            before(:each) do
                @user_id = user_teams(:adam_confirmed).id
                @res = @team.member? @team_id, @user_id
            end
            it "should return true" do
                expect(@res).to be true
            end
        end
        context "has not accepted" do
            before(:each) do
                @user_id = user_teams(:adam_invited_expired).id
                @res = @team.member? @team_id, @user_id
            end 
            it "should return false" do
                expect(@res).to be false
            end 
        end
    end
    context "#add_owner" do
        fixtures :users, :teams

        # covered by POST /teams
    end
end

require_relative '../spec_helper'

describe ".Organization" do
    fixtures :teams
    before(:each) do
        @team = Organization.new
    end

    shared_examples_for "team_connections_manager" do
        it "should return a result" do
            expect(@mysql_result.count).to be > 0
        end
        it "should include id" do
            @mysql_result.each_with_index do |res,i|
                expect(@res[i]["id"]).to eq(res["id"])
            end                                                         
        end  
        it "should include contact_id" do
            @mysql_result.each_with_index do |res,i|
                expect(decrypt(@res[i]["contact_id"]).to_i).to eq(res["contact_id"])
            end
        end
        it "should include contact_first_name" do
            @mysql_result.each_with_index do |res,i|
                expect(@res[i]["contact_first_name"]).to eq(res["contact_first_name"])
            end                                                                 
        end  
        it "should include team_plan" do
            @mysql_result.each_with_index do |res,i|
                expect(@res[i]["team_plan"]).to eq(res["team_plan"])
            end
        end
        it "should include expires" do
            @mysql_result.each_with_index do |res,i|
                expect(@res[i]["expires"]).to eq(res["expires"].to_s(:db))
            end
        end
    end

    shared_examples_for "team_connections_recruiter" do
        it "should include user_id as user_id" do
            @mysql_result.each_with_index do |res,i|
                expect(decrypt(@res[i]["user_id"]).to_i).to eq(res["user_id"])
            end
        end
        it "should include user first_name" do
            @mysql_result.each_with_index do |res,i|
                expect(@res[i]["first_name"]).to eq(res["first_name"])
            end                                                 
        end
        it "should include user_profile" do
            @mysql_result.each_with_index do |res,i|
                expect(decrypt(@res[i][:user_profile][:id]).to_i).to eq(res["user_id"])
            end
        end
        it "should include user email" do 
            @mysql_result.each_with_index do |res,i|
                expect(@res[i]["email"]).to eq(res["email"])
            end                                                 
        end
    end

    context "#get_team_connections_requested" do
        fixtures :users, :user_connections, :teams, :user_teams, :seats, :plans
        context "manager" do
            before(:each) do
                @res = @team.get_team_connections_requested user_connections(:elina_bteam_priority).team.id, user_connections(:elina_bteam_priority).team.plan.name
                @mysql_result = @mysql_client.query("SELECT user_connections.id, 'manager' as team_plan,  user_connections.contact_id, user_connections.created_at, user_connections.updated_at, user_teams.seat_id, user_teams.expires, contact.first_name as contact_first_name FROM `user_connections` inner join users on user_connections.user_id = users.id INNER JOIN users contact ON contact.id = user_connections.contact_id inner join user_teams on user_connections.contact_id = user_teams.user_id WHERE (user_connections.team_id = #{user_connections(:elina_bteam_priority).team.id}) ORDER BY user_connections.created_at DESC")
            end
            it_behaves_like "team_connections_manager"
        end
        context "recruiter" do
            before(:each) do
                @res = @team.get_team_connections_requested user_connections(:elina_dteam_sponsored).team.id, user_connections(:elina_dteam_sponsored).team.plan.name
                @mysql_result = @mysql_client.query("SELECT user_connections.*, 'recruiter' as team_plan, users.id, users.first_name, users.email, user_teams.seat_id, user_teams.expires, contact.first_name as contact_first_name FROM `user_connections` inner join users on user_connections.user_id = users.id INNER JOIN users contact ON contact.id = user_connections.contact_id inner join user_teams on user_connections.contact_id = user_teams.user_id WHERE (user_connections.team_id = #{user_connections(:elina_bteam_priority).team.id}) ORDER BY user_connections.created_at DESC")
            end
            it_behaves_like "team_connections_recruiter"
        end
    end
    context "#invite_member" do
        fixtures :users, :teams, :user_teams, :seats
        before(:each) do
            @new_team = teams(:different_team_for_invite)
        end
        context "not on another team" do
            before(:each) do
                @email = "adam+not+on+another+team@wired7.com"
                @res = @team.invite_member @new_team.id, @new_team[:user_id], nil, @email, seats(:priority).id, nil, nil, nil 
            end
            it "should not return an error" do
                expect(@res.errors.messages).to be_empty
            end
        end
        context "on another team prior to expiration" do
            before(:each) do
                @current_user_team = user_teams(:adam_confirmed_b_team)
                @res = @team.invite_member @new_team.id, @new_team[:user_id], nil, @current_user_team.user_email, seats(:priority).id, nil, nil, nil 
            end 
            it "should return error" do
                expect(@res.errors.messages[:user_email][0]).to eq "this user is exclusively working with another team"
            end
        end
        context "on another team after expiration" do
            before(:each) do
                @current_user_team = user_teams(:adam_confirmed_b_team)
                @mysql_client.query("update user_teams set expires = '#{1.day.ago.to_s(:db)}' where user_email = '#{@current_user_team.user_email}'")
                @res = @team.invite_member @new_team.id, @new_team[:user_id], nil, @current_user_team.user_email, seats(:priority).id, nil, nil, nil
            end 
            it "should return error" do
                expect(@res.errors.messages).to be_empty 
            end
        end
    end


    context "#get_team_notifications" do
        fixtures :users, :teams, :user_teams, :seats, :sprint_timelines, :contributors, :notifications
        before(:each) do
            params = {
                "id" => teams(:join_priority).id
            }
            @res = @team.get_team_notifications params
            puts @res.inspect
        end
        it "should return a single result", :focus => true do
            expect(@res[:data].length).to be 1
            expect(@res[:meta][:count]).to be 1
        end
        context "while seat is active" do

        end
    end
end

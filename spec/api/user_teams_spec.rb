require 'spec_helper'
require 'api_helper'

describe "/user-teams" do

    fixtures :users, :seats
    before(:all) do
        @CREATE_TOKENS=true
    end

    shared_examples_for "invites_teams" do
        it "should return invite id" do
            @team_invite_result.each_with_index do |r,i|
                expect(@res[i]["id"]).to eq(r["id"])
            end
        end
        it "should return sender_id" do
            @team_invite_result.each_with_index do |r,i|
                expect(@res[i]["sender_id"]).to eq(r["sender_id"])
            end
        end
        it "should return seat_id" do
            @team_invite_result.each_with_index do |r,i|
                expect(@res[i]["seat_id"]).to eq(r["seat_id"])
            end
        end
        it "should not return token" do
            @team_invite_result.each_with_index do |r,i|
                expect(@res[i].keys).to_not include "token"
            end
        end
    end

    describe "POST /" do
        context "valid team_id" do 
            fixtures :teams, :plans
            before(:each) do
                @team = teams(:ateam).id
                @email = "adam+gets+invited@wired7.com"
                @user_id = users(:adam).id
                @seat = seats(:member).id
            end
            context "non-member" do
                before(:each) do
                    post "/user-teams", { :user_email => @email, :team_id => @team, :seat_id => @seat }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                end
                it_behaves_like "unauthorized"
            end
            context "member" do
                fixtures :user_teams
                context "valid" do
                    before(:each) do
                        post "/user-teams", { :user_email => @email, :team_id => @team, :seat_id => @seat }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                        @res = [JSON.parse(last_response.body)]
                        @single_res = @res[0]
                        @team_invite_result = @mysql_client.query("select * from user_teams where user_email = '#{@email}'")
                    end
                    it "should return email" do
                        expect(@single_res["email"]).to eq(@team_invite_result.first["email"])
                    end
                    it "should return accepted = false" do
                        expect(@single_res["accepted"]).to be false
                    end 
                    it "should create a new user" do
                        expect(@mysql_client.query("select * from users where id = #{@single_res["user_id"]}").count).to eq 1
                    end
                    it "should return user_id" do
                        expect(@single_res["user_id"]).to eq(@team_invite_result.first["user_id"]) 
                    end
                    it "should store token" do
                        expect(@team_invite_result.first["token"]).to_not be nil
                    end
                    it_behaves_like "invites_teams"
                end 
                context "unauthorized seat id" do
                    before(:each) do
                        post "/user-teams", { :user_email => @email, :team_id => @team, :seat_id => seats(:owner).id }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                        @res = JSON.parse(last_response.body)
                    end
                    it "should return error message" do
                        expect(@res["errors"][0]["detail"]).to eq("seat type not permitted")
                    end
                end
            end
            context "admin" do
                before(:each) do
                    post "/user-teams", { :user_email => @email, :team_id => @team, :seat_id => @seat }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@admin_w7_token}"}
                    @res = [JSON.parse(last_response.body)]
                    @single_res = @res[0]
                    @team_invite_result = @mysql_client.query("select * from user_teams where user_email = '#{@email}'")
                end 
                it_behaves_like "invites_teams"
            end
            context "talent not member" do
                fixtures :user_teams
                before(:each) do
                    @mysql_client.query("update user_teams set seat_id = #{seats(:priority).id} where user_id = #{@user}")
                    post "/user-teams", { :user_email => @email, :team_id => @team, :seat_id => @seat }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                end
                it_behaves_like "unauthorized"
            end
        end
        context "invalid team_id" do
            before(:each) do
                post "/user-teams", { :user_email => "adam+123@wired7.com", :team_id => 27, :seat_id => seats(:member).id }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
            end
            it_behaves_like "unauthorized"
        end
    end

    describe "POST /" do
        fixtures :teams, :user_teams
        context "valid token" do
            before(:each) do
                post "/user-teams/token", { :token => user_teams(:adam_confirmed_b_team).token }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                @res = [JSON.parse(last_response.body)]
                @team_invite_result = @mysql_client.query("select * from user_teams where id = '#{user_teams(:adam_confirmed_b_team).id}'")
            end
            it_behaves_like "invites_teams"
            it "should set accepted = true" do
                expect(@res[0]["accepted"]).to be true 
            end
            it "should update the record" do
                expect(@team_invite_result.first["accepted"]).to eq 1
            end
        end
        context "invalid token" do
            after(:each) do 
                expect(JSON.parse(last_response.body)["error"]).to eq("This invite is invalid or has expired")
            end
            context "expired" do
                it "should return error message" do
                    post "/user-teams/token", { :token => user_teams(:adam_invited_expired).token  }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                end
            end
            context "bogus" do
                it "should return error message" do
                    post "/user-teams/token", { :token => "999"  }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                end
            end
            context "another user's" do
                it "should return error message" do
                    post "/user-teams/token", { :token => user_teams(:adam_protected).token }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                end
            end
        end
    end

    describe "GET /" do
        context "valid team_id" do
            fixtures :teams
            before(:each) do
                @team = teams(:ateam).id
            end
            context "non-member" do
                before(:each) do
                    get "/user-teams?team_id=#{@team}", nil, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                end
                it_behaves_like "unauthorized"
            end
            context "member" do
                fixtures :user_teams
                before(:each) do
                    get "/user-teams?team_id=#{@team}", nil, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                    @res = JSON.parse(last_response.body)
                    @team_invite_result = @mysql_client.query("select * from user_teams where team_id = #{@team} ORDER BY ID DESC")
                end 
                it_behaves_like "invites_teams"
            end
            context "talent not member" do
                fixtures :user_teams
                before(:each) do
                    @mysql_client.query("update user_teams set seat_id = #{seats(:priority).id} where user_id = #{@user}")
                    get "/user-teams?team_id=#{@team}", nil, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                end
                it_behaves_like "unauthorized"
            end
        end
        context "invalid team_id" do
            before(:each) do
                get "/user-teams?team_id=27", {}, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
            end
            it_behaves_like "unauthorized"
        end
    end
end

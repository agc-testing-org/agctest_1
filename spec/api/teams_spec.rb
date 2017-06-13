require 'spec_helper'
require 'api_helper'

describe "/teams" do

    fixtures :users, :plans, :seats

    before(:all) do
        @CREATE_TOKENS=true
    end

    shared_examples_for "teams" do
        it "should return id" do
            @team_results.each_with_index do |team_result,i|
                expect(@teams[i]["id"]).to eq(team_result["id"])
            end
        end
        it "should return name" do
            @team_results.each_with_index do |team_result,i|
                expect(@teams[i]["name"]).to eq(team_result["name"])
            end                                                     
        end 
        it "should return owner" do
            @team_results.each_with_index do |team_result,i|
                expect(@teams[i]["user_id"]).to_not be nil
                expect(@teams[i]["user_id"]).to eq(team_result["user_id"])
            end                                                    
        end 
        it "should return plan_id" do
            @team_results.each_with_index do |team_result,i|
                expect(@teams[i]["plan_id"]).to eq(team_result["plan_id"])
            end  
        end
    end

    describe "POST /" do
        before(:each) do
            @name = "NEW TEAM"
        end
        context "owner or admin" do
            context "owner" do
                fixtures :user_teams
                context "valid fields" do
                    before(:each) do
                        post "/teams", { :name => @name, :plan_id => plans(:manager).id }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                        @team_results = @mysql_client.query("select * from teams")
                        @teams = [JSON.parse(last_response.body)]
                    end
                    it_behaves_like "teams"

                    context "user_teams" do
                        before(:each) do
                            @user_team_result = @mysql_client.query("select * from user_teams ORDER BY id DESC").first
                        end
                        it "saves owner as sender_id" do
                            expect(@user_team_result["sender_id"]).to eq(@user)
                        end
                        it "saves owner as user_id" do
                            expect(@user_team_result["user_id"]).to eq(@user)
                        end 
                        it "saves accepted as true" do
                            expect(@user_team_result["accepted"]).to eq 1 
                        end
                        it "saves owner as member" do
                            expect(@user_team_result["seat_id"]).to eq(seats(:member).id)
                        end
                    end
                end
                context "invalid fields" do
                    context "name < 3 char" do
                        before(:each) do
                            post "/teams", { :name => "12", :plan_id => plans(:manager).id }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@admin_w7_token}"}
                            @team_results = @mysql_client.query("select * from teams")
                            @error = JSON.parse(last_response.body)
                        end
                        it "should not save the result" do
                            expect(@team_results.count).to eq(0)
                        end
                        it "should return error message" do
                            expect(@error["errors"][0]["detail"]).to eq("Please enter a more descriptive team name")
                        end
                    end
                    context "name (exists already)" do
                        fixtures :teams
                        before(:each) do
                            post "/teams", { :name => "ATEAM", :plan_id => plans(:manager).id }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@admin_w7_token}"}
                            @error = JSON.parse(last_response.body)
                        end
                        it "should return error message" do
                            expect(@error["errors"][0]["detail"]).to eq("This name is not available")
                        end
                    end
                    context "invalid plan id" do
                        before(:each) do
                            post "/teams", { :name => "ATEAMNEW", :plan_id => 33 }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@admin_w7_token}"}
                            @error = JSON.parse(last_response.body)
                        end
                        it "should return error message" do
                            expect(@error["errors"][0]["detail"]).to eq("This name is not available")
                        end
                    end
                end
            end

            context "admin" do
                before(:each) do
                    post "/teams", { :name => @name, :plan_id => plans(:manager).id }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@admin_w7_token}"}
                    @team_results = @mysql_client.query("select * from teams")
                    @teams = [JSON.parse(last_response.body)]
                end
                it_behaves_like "teams"
            end
        end
        context "unauthorized" do
            before(:each) do
                post "/teams", { :name => "12", :plan_id => plans(:manager) }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
            end
            it_behaves_like "unauthorized"
        end
    end

    describe "GET /" do
        context "teams" do
            fixtures :teams, :user_teams
            before(:each) do
                get "/teams", {}, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                @team_results = @mysql_client.query("select teams.* from teams JOIN user_teams ON user_teams.team_id = teams.id where user_teams.user_id = #{@user} AND user_teams.accepted = true")
                @teams = JSON.parse(last_response.body)
            end
            it_behaves_like "teams"
        end
        context "no teams" do
            before(:each) do
                get "/teams", {}, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                @teams = JSON.parse(last_response.body)
            end
            it "should return empty" do
                expect(@teams).to be_empty
            end
        end
    end

    describe "GET /:id" do
        fixtures :teams
        before(:each) do
            @team = teams(:ateam).id
        end
        context "member" do
            fixtures :user_teams
            before(:each) do
                get "/teams/#{@team}", {}, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                @team_results = @mysql_client.query("select teams.* from teams JOIN user_teams ON user_teams.team_id = teams.id where user_teams.user_id = #{@user} and teams.id = #{@team}")
                @teams = [JSON.parse(last_response.body)]
            end
            it_behaves_like "teams"
            it "should return owner / user" do
                expect(@teams[0]["user"]["id"]).to eq(teams(:ateam).user.id)
            end
            it "should return default seat_id" do
                expect(@teams[0]["default_seat_id"]).to eq(teams(:ateam).plan.seat.id)
            end
            it "should return a list of permitted seats (to invite others)" do
                expect(@teams[0]["seats"].to_json).to eq([{:id => seats(:priority).id},{:id => seats(:member).id}].to_json)
            end
            it "should return show true" do
                expect(@teams[0]["show"]).to be true
            end
        end
        context "admin" do
            fixtures :user_teams
            before(:each) do
                get "/teams/#{@team}", {}, {"HTTP_AUTHORIZATION" => "Bearer #{@admin_w7_token}"}
                @team_results = @mysql_client.query("select teams.* from teams JOIN user_teams ON user_teams.team_id = teams.id where user_teams.user_id = #{@user} and teams.id = #{@team}")
                @teams = [JSON.parse(last_response.body)]
            end
            it_behaves_like "teams"
            it "should return a list of all seats" do
                expect(@teams[0]["seats"].to_json).to eq([{:id => seats(:owner).id},{:id => seats(:sponsored).id},{:id => seats(:priority).id},{:id => seats(:member).id},{:id => seats(:free_agent).id}].to_json)
            end
            it "should return show true" do
                expect(@teams[0]["show"]).to be true
            end 
        end
        context "non-member seat" do
            fixtures :user_teams
            before(:each) do
                @mysql_client.query("update user_teams set seat_id = #{seats(:priority).id} where user_id = #{@user}")
                get "/teams/#{@team}", {}, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                @team_results = @mysql_client.query("select teams.* from teams JOIN user_teams ON user_teams.team_id = teams.id where user_teams.user_id = #{@user} and teams.id = #{@team}")
                @teams = [JSON.parse(last_response.body)]
            end
            it_behaves_like "teams"
            it "should return show false" do
                expect(@teams[0]["show"]).to be false
            end
        end
        context "not member" do
            before(:each) do
                get "/teams/#{@team}", {}, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
            end 
            it_behaves_like "unauthorized"
        end
    end
end

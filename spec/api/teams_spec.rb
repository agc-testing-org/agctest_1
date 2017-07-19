require 'spec_helper'
require 'api_helper'

describe "/teams" do

    fixtures :users, :plans, :seats

    before(:all) do
        @CREATE_TOKENS=true
        @per_page = 10
    end

    shared_examples_for "teams" do
        it "should return id" do
            expect(@team_results.count).to be > 0
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
                expect(decrypt(@teams[i]["user_id"]).to_i).to eq(team_result["user_id"])
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
                            expect(@user_team_result["sender_id"]).to eq(decrypt(@user).to_i)
                        end
                        it "saves owner as user_id" do
                            expect(@user_team_result["user_id"]).to eq(decrypt(@user).to_i)
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
                    context "name < 2 char" do
                        before(:each) do
                            post "/teams", { :name => "A", :plan_id => plans(:manager).id }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@admin_w7_token}"}
                        end 
                        it_behaves_like "error", "team name must be 2-30 characters" 
                    end
                    context "name > 30 char" do
                        before(:each) do
                            post "/teams", { :name => "A"*31, :plan_id => plans(:manager).id }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@admin_w7_token}"}
                        end 
                        it_behaves_like "error", "team name must be 2-30 characters" 
                    end
                    context "name (exists already)" do
                        fixtures :teams
                        before(:each) do
                            post "/teams", { :name => "ATEAM", :plan_id => plans(:manager).id }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@admin_w7_token}"} 
                        end
                        it_behaves_like "error", "this name is not available"
                    end
                    context "invalid plan id" do
                        before(:each) do
                            post "/teams", { :name => "ATEAMNEW", :plan_id => 33 }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@admin_w7_token}"}
                        end
                        it_behaves_like "error", "invalid plan_id"
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
            it_behaves_like "unauthorized_admin"
        end
    end

    describe "GET /" do
        context "teams" do
            fixtures :teams, :user_teams
            before(:each) do
                get "/teams", {}, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                @team_results = @mysql_client.query("select teams.* from teams JOIN user_teams ON user_teams.team_id = teams.id where user_teams.user_id = #{decrypt(@user).to_i} AND user_teams.accepted = true")
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
                @team_results = @mysql_client.query("select teams.* from teams where teams.id = #{@team}")
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
                @team_results = @mysql_client.query("select teams.* from teams where teams.id = #{@team}")
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
                @mysql_client.query("update user_teams set seat_id = #{seats(:priority).id} where user_id = #{decrypt(@user).to_i}")
                get "/teams/#{@team}", {}, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                @team_results = @mysql_client.query("select teams.* from teams where teams.id = #{@team}")
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
            it_behaves_like "not_found"
        end
    end

    shared_examples_for "team_notifications" do
        it "should return id" do
            @notification_results.each_with_index do |n,i|
                expect(n["id"]).to eq(@res[i]["id"])
            end 
        end 
    end

    describe "GET /teams/:id/notifications" do
        fixtures :sprint_timelines, :user_notifications, :teams, :user_teams, :contributors
        before(:each) do
            @team = teams(:ateam).id
        end
        context "signed in" do 
            before(:each) do
                get "/teams/#{@team}/notifications", {}, {"HTTP_AUTHORIZATION" => "Bearer #{@admin_w7_token}"}
                @res = JSON.parse(last_response.body)["data"]
                puts @res.to_json
                base_query = "SELECT sprint_timelines.*, user_notifications.id, user_notifications.read FROM sprint_timelines inner join user_notifications inner join user_teams INNER join contributors ON sprint_timelines.contributor_id = contributors.id WHERE (sprint_timelines.id=user_notifications.sprint_timeline_id and user_teams.team_id = #{teams(:ateam).id} and user_notifications.user_id = user_teams.user_id and user_teams.accepted = 1 and user_teams.seat_id in (#{seats(:sponsored).id}, #{seats(:priority).id}) AND sprint_timelines.diff IN('vote','comment','winner') and contributors.user_id != sprint_timelines.user_id)"
                @notification_results = @mysql_client.query("#{base_query} limit #{@per_page}").to_json
                @notification_count = @mysql_client.query(base_query).count
            end
            it "should return count" do
                expect(JSON.parse(last_response.body)["meta"]["count"]).to eq @notification_count
            end 
            it_behaves_like "team_notifications"
            it_behaves_like "ok"
        end
        context "not signed in" do
            before(:each) do
                get "/teams/#{@team}/notifications"
            end
            it_behaves_like "unauthorized"
        end
        context "paging" do
            before(:each) do
                @page = 2
                get "/teams/#{@team}/notifications", {}, {"HTTP_AUTHORIZATION" => "Bearer #{@admin_w7_token}"}
                @res = JSON.parse(last_response.body)["data"]
                base_query = "SELECT sprint_timelines.*, user_notifications.id, user_notifications.read FROM sprint_timelines inner join user_notifications inner join user_teams INNER join contributors ON sprint_timelines.contributor_id = contributors.id WHERE (sprint_timelines.id=user_notifications.sprint_timeline_id and user_teams.team_id = #{teams(:ateam).id} and user_notifications.user_id = user_teams.user_id and user_teams.accepted = 1 and user_teams.seat_id in (#{seats(:sponsored).id}, #{seats(:priority).id}) AND sprint_timelines.diff IN('vote','comment','winner') and contributors.user_id != sprint_timelines.user_id)"
                @notification_results = @mysql_client.query("#{base_query} limit #{@per_page} offset #{(@page - 1) * @per_page}")
                @notification_count = @mysql_client.query(base_query).count
            end
            it "should return count" do
                expect(JSON.parse(last_response.body)["meta"]["count"]).to eq @notification_count
            end
            it_behaves_like "ok"
            it_behaves_like "team_notifications"
        end
    end
end

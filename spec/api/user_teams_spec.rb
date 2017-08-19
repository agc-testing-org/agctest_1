require 'spec_helper'
require 'api_helper'

describe "/user-teams" do

    fixtures :users, :seats, :notifications
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
                expect(decrypt(@res[i]["sender_id"]).to_i).to eq(r["sender_id"])
            end
        end
        it "should return seat_id" do
            @team_invite_result.each_with_index do |r,i|
                expect(@res[i]["seat_id"]).to eq(r["seat_id"])
            end
        end
        it "should return profile_id" do
            @team_invite_result.each_with_index do |r,i|
                expect(@res[i]["profile_id"]).to eq(r["profile_id"])
            end
        end
        it "should return job_id" do
            @team_invite_result.each_with_index do |r,i|
                expect(@res[i]["job_id"]).to eq(r["job_id"])
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
                @seat = seats(:member).id
            end
            context "invalid email" do
                before(:each) do
                    post "/user-teams", { :user_email => "a@1.", :team_id => @team, :seat_id => @seat }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                end
                it_behaves_like "error", "please enter a valid email address"
            end
            context "non-member" do
                before(:each) do
                    post "/user-teams", { :user_email => @email, :team_id => @team, :seat_id => @seat }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                end
                it_behaves_like "not_found"
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
                        expect(@mysql_client.query("select * from users where id = #{decrypt(@single_res["user_id"]).to_i}").count).to eq 1
                    end
                    it "should return user_id" do
                        expect(decrypt(@single_res["user_id"]).to_i).to eq(@team_invite_result.first["user_id"]) 
                    end
                    it "should store token" do
                        expect(@team_invite_result.first["token"]).to_not be nil
                    end
                    it_behaves_like "invites_teams"
                    it_behaves_like "created"
                    context "already invited" do
                        before(:each) do
                            post "/user-teams", { :user_email => @email, :team_id => @team, :seat_id => @seat }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                        end
                        it_behaves_like "error", "this email address has an existing invitation"
                    end
                end
                context "share profile" do
                    before(:each) do
                        @seat = seats(:share).id 
                        post "/user-teams", { :user_email => @email, :team_id => @team, :seat_id => @seat, :profile_id => users(:adam).id }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                        @res = [JSON.parse(last_response.body)]
                        @single_res = @res[0]
                        @team_invite_result = @mysql_client.query("select * from user_teams where user_email = '#{@email}' AND seat_id = #{@seat}")
                    end
                    it "should save profile_id", :focus => true do
                        expect(@team_invite_result.first["profile_id"]).to eq decrypt(users(:adam).id).to_i
                    end
                    it_behaves_like "invites_teams"
                    context "multiple unique shares" do
                        before(:each) do
                            post "/user-teams", { :user_email => @email, :team_id => @team, :seat_id => @seat, :profile_id => users(:adam_admin).id }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                            @res = [JSON.parse(last_response.body)]
                            @single_res = @res[0]
                            @team_invite_result = @mysql_client.query("select * from user_teams where user_email = '#{@email}' AND profile_id = #{decrypt(users(:adam_admin).id)}")
                        end
                        it_behaves_like "invites_teams"
                    end
                    context "same share" do
                        before(:each) do
                            post "/user-teams", { :user_email => @email, :team_id => @team, :seat_id => @seat, :profile_id => users(:adam).id  }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                        end
                        it_behaves_like "error", "this email address has an existing invitation"
                    end
                    context "invite to team after share" do
                        before(:each) do
                            post "/user-teams", { :user_email => @email, :team_id => @team, :seat_id => seats(:member).id }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                            @res = [JSON.parse(last_response.body)]
                            @single_res = @res[0]
                            @team_invite_result = @mysql_client.query("select * from user_teams where user_email = '#{@email}' AND profile_id = #{decrypt(users(:adam_admin).id)}")
                        end
                        it_behaves_like "invites_teams"
                    end
                end
                context "with job" do
                    fixtures :jobs
                    before(:each) do
                        post "/user-teams", { :user_email => @email, :team_id => @team, :seat_id => @seat, :job_id => jobs(:developer).id }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                        @res = [JSON.parse(last_response.body)]
                        @single_res = @res[0]
                        @team_invite_result = @mysql_client.query("select * from user_teams where user_email = '#{@email}' AND seat_id = #{@seat}")
                    end
                    it "should save job_id", :focus => true do
                        expect(@team_invite_result.first["job_id"]).to eq jobs(:developer).id
                    end
                end
                context "unauthorized seat id" do
                    before(:each) do
                        post "/user-teams", { :user_email => @email, :team_id => @team, :seat_id => seats(:owner).id }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                    end
                    it_behaves_like "error", "invalid seat_id"
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
                    @mysql_client.query("update user_teams set seat_id = #{seats(:priority).id} where user_id = #{decrypt(@user).to_i}")
                    post "/user-teams", { :user_email => @email, :team_id => @team, :seat_id => @seat }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                end
                it_behaves_like "not_found"
            end
        end
        context "invalid team_id" do
            before(:each) do
                post "/user-teams", { :user_email => "adam+123@wired7.com", :team_id => 27, :seat_id => seats(:member).id }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
            end
            it_behaves_like "not_found"
        end
    end

    describe "POST /token" do
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
            it_behaves_like "ok"
        end
        context "invalid token" do
            context "expired" do
                before(:each) do
                    post "/user-teams/token", { :token => user_teams(:adam_confirmed_expired).token  }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                end
                it_behaves_like "error", "this invitation has expired"
            end
            context "bogus" do
                before(:each) do 
                    post "/user-teams/token", { :token => "999"  }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                end
                it_behaves_like "error", "this invitation is invalid"
            end
            context "another user's" do
                before(:each) do 
                    post "/user-teams/token", { :token => user_teams(:adam_protected).token }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                end
                it_behaves_like "error", "this invitation is invalid"
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
                it_behaves_like "not_found"
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
                    @mysql_client.query("update user_teams set seat_id = #{seats(:priority).id} where user_id = #{decrypt(@user).to_i}")
                    get "/user-teams?team_id=#{@team}", nil, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                end
                it_behaves_like "not_found"
            end
        end
        context "invalid team_id" do
            before(:each) do
                get "/user-teams?team_id=27", {}, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
            end
            it_behaves_like "not_found"
        end
    end

    shared_examples_for "team-aggregates" do
        it "should return user_id as id" do
            expect(@result.count).to be > 0
            @result.each_with_index do |r,i|
                expect(decrypt(@res[i]["id"]).to_i).to eq r["id"]
            end
        end
        it "should return count" do
            @result.each_with_index do |r,i|
                expect(@res[i]["count"]).to eq r["count"]
            end
        end
    end

    describe "GET /:id/team-comments" do
        fixtures :teams, :user_teams, :sprint_timelines, :contributors, :sprint_states, :sprints, :sprint_states, :projects, :comments
        context "valid team_id" do
            before(:each) do
                get "/user-teams/#{user_teams(:adam_admin_adam_admin_team).team_id}/team-comments?seat_id=#{user_teams(:adam_admin_adam_admin_team).seat_id}", nil, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                @res = JSON.parse(last_response.body)
                @result = @mysql_client.query("SELECT count(distinct(sprint_timelines.id)) as count, users.id as id FROM `sprint_timelines` RIGHT JOIN users ON (users.id = sprint_timelines.user_id AND sprint_timelines.notification_id=#{notifications(:comment).id}) LEFT JOIN comments ON (sprint_timelines.comment_id = comments.id and sprint_timelines.comment_id IS NOT NULL) INNER JOIN user_teams ON user_teams.user_id = users.id WHERE (sprint_timelines.notification_id=#{notifications(:comment).id} OR sprint_timelines.notification_id IS NULL) AND `user_teams`.`seat_id` = #{user_teams(:adam_admin_adam_admin_team).seat_id} AND `user_teams`.`team_id` = #{user_teams(:adam_admin_adam_admin_team).team_id} GROUP BY users.id")
            end
            it_behaves_like "team-aggregates"
        end
        context "not member" do
            fixtures :seats
            before(:each) do
                @mysql_client.query("update user_teams set seat_id = #{seats(:sponsored).id} where id = #{user_teams(:adam_confirmed_adam_admin_team).id}")
                get "/user-teams/#{user_teams(:adam_admin_adam_admin_team).team_id}/team-comments?seat_id=#{user_teams(:adam_admin_adam_admin_team).seat_id}", nil, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
            end
            it_behaves_like "not_found"
        end
    end

    describe "GET /:id/team-votes" do
        fixtures :teams, :user_teams, :sprint_timelines, :contributors, :sprint_states, :sprints, :sprint_states, :projects, :votes
        context "valid team_id" do
            before(:each) do
                get "/user-teams/#{user_teams(:adam_admin_adam_admin_team).team_id}/team-votes?seat_id=#{user_teams(:adam_admin_adam_admin_team).seat_id}", nil, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                @res = JSON.parse(last_response.body)
                @result = @mysql_client.query("SELECT count(distinct(sprint_timelines.id)) as count, users.id as id FROM `sprint_timelines` RIGHT JOIN users ON (users.id = sprint_timelines.user_id AND sprint_timelines.notification_id=#{notifications(:vote).id}) LEFT JOIN votes ON (sprint_timelines.vote_id = votes.id and sprint_timelines.vote_id IS NOT NULL) INNER JOIN user_teams ON user_teams.user_id = users.id WHERE (sprint_timelines.notification_id=#{notifications(:vote).id} OR sprint_timelines.notification_id IS NULL) AND `user_teams`.`seat_id` = #{user_teams(:adam_admin_adam_admin_team).seat_id} AND `user_teams`.`team_id` = #{user_teams(:adam_admin_adam_admin_team).team_id} GROUP BY users.id")
            end
            it_behaves_like "team-aggregates"
        end
        context "not member" do
            fixtures :seats 
            before(:each) do
                @mysql_client.query("update user_teams set seat_id = #{seats(:sponsored).id} where id = #{user_teams(:adam_confirmed_adam_admin_team).id}")
                get "/user-teams/#{user_teams(:adam_admin_adam_admin_team).team_id}/team-votes?seat_id=#{user_teams(:adam_admin_adam_admin_team).seat_id}", nil, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
            end 
            it_behaves_like "not_found"
        end 
    end

    describe "GET /:id/team-contributors" do
        fixtures :teams, :user_teams, :sprint_timelines, :contributors, :sprint_states, :sprints, :sprint_states, :projects
        context "valid team_id" do
            before(:each) do                    
                get "/user-teams/#{user_teams(:adam_admin_adam_admin_team).team_id}/team-contributors?seat_id=#{user_teams(:adam_admin_adam_admin_team).seat_id}", nil, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                @res = JSON.parse(last_response.body)                               
                @result = @mysql_client.query("SELECT count(distinct(contributors.id)) as count, users.id as id FROM `contributors` RIGHT JOIN users ON (contributors.user_id = users.id) INNER JOIN user_teams ON user_teams.user_id = users.id WHERE `user_teams`.`seat_id` = #{user_teams(:adam_admin_adam_admin_team).seat_id} AND `user_teams`.`team_id` = #{user_teams(:adam_admin_adam_admin_team).team_id} GROUP BY users.id")
            end                                                                                                 
            it_behaves_like "team-aggregates"               
        end    
        context "not member" do
            fixtures :seats 
            before(:each) do
                @mysql_client.query("update user_teams set seat_id = #{seats(:sponsored).id} where id = #{user_teams(:adam_confirmed_adam_admin_team).id}")
                get "/user-teams/#{user_teams(:adam_admin_adam_admin_team).team_id}/team-contributors?seat_id=#{user_teams(:adam_admin_adam_admin_team).seat_id}", nil, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
            end 
            it_behaves_like "not_found"
        end 
    end 

    describe "GET /:id/team-comments-received" do
        fixtures :teams, :user_teams, :sprint_timelines, :contributors, :sprint_states, :sprints, :sprint_states, :projects, :comments
        context "valid team_id" do
            before(:each) do
                get "/user-teams/#{user_teams(:adam_admin_adam_admin_team).team_id}/team-comments-received?seat_id=#{user_teams(:adam_admin_adam_admin_team).seat_id}", nil, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                @res = JSON.parse(last_response.body)
                @result = @mysql_client.query("SELECT count(distinct(sprint_timelines.id)) as count, users.id as id FROM `sprint_timelines` LEFT JOIN contributors ON (sprint_timelines.contributor_id = contributors.id AND contributors.user_id != sprint_timelines.user_id AND sprint_timelines.notification_id=#{notifications(:comment).id}) RIGHT JOIN users ON (users.id = contributors.user_id) LEFT JOIN comments ON (sprint_timelines.comment_id = comments.id and sprint_timelines.comment_id IS NOT NULL) INNER JOIN user_teams ON user_teams.user_id = users.id WHERE (sprint_timelines.notification_id=#{notifications(:comment).id} OR sprint_timelines.notification_id IS NULL) AND `user_teams`.`seat_id` = #{user_teams(:adam_admin_adam_admin_team).seat_id} AND `user_teams`.`team_id` = #{user_teams(:adam_admin_adam_admin_team).team_id} GROUP BY users.id")
            end
            it_behaves_like "team-aggregates"
        end
        context "not member" do
            fixtures :seats 
            before(:each) do
                @mysql_client.query("update user_teams set seat_id = #{seats(:sponsored).id} where id = #{user_teams(:adam_confirmed_adam_admin_team).id}")
                get "/user-teams/#{user_teams(:adam_admin_adam_admin_team).team_id}/team-comments-received?seat_id=#{user_teams(:adam_admin_adam_admin_team).seat_id}", nil, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
            end 
            it_behaves_like "not_found"
        end 
    end

    describe "GET /:id/team-votes-received" do
        fixtures :teams, :user_teams, :sprint_timelines, :contributors, :sprint_states, :sprints, :sprint_states, :projects, :votes
        context "valid team_id" do
            before(:each) do                    
                get "/user-teams/#{user_teams(:adam_admin_adam_admin_team).team_id}/team-votes-received?seat_id=#{user_teams(:adam_admin_adam_admin_team).seat_id}", nil, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                @res = JSON.parse(last_response.body)                               
                @result = @mysql_client.query("SELECT count(distinct(sprint_timelines.id)) as count, users.id as id FROM `sprint_timelines` LEFT JOIN contributors ON (sprint_timelines.contributor_id = contributors.id AND contributors.user_id != sprint_timelines.user_id AND sprint_timelines.notification_id=#{notifications(:vote).id}) RIGHT JOIN users ON users.id = contributors.user_id LEFT JOIN votes ON (sprint_timelines.vote_id = votes.id and sprint_timelines.vote_id IS NOT NULL) INNER JOIN user_teams ON user_teams.user_id = users.id WHERE (sprint_timelines.notification_id=#{notifications(:vote).id} OR sprint_timelines.notification_id IS NULL) AND `user_teams`.`seat_id` = #{user_teams(:adam_admin_adam_admin_team).seat_id} AND `user_teams`.`team_id` = #{user_teams(:adam_admin_adam_admin_team).team_id} GROUP BY users.id")
            end                                                                                                 
            it_behaves_like "team-aggregates"               
        end                                                         
        context "not member" do
            fixtures :seats 
            before(:each) do
                @mysql_client.query("update user_teams set seat_id = #{seats(:sponsored).id} where id = #{user_teams(:adam_confirmed_adam_admin_team).id}")
                get "/user-teams/#{user_teams(:adam_admin_adam_admin_team).team_id}/team-votes-received?seat_id=#{user_teams(:adam_admin_adam_admin_team).seat_id}", nil, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
            end 
            it_behaves_like "not_found"
        end 
    end

    describe "GET /:id/team-contributors-received" do
        fixtures :teams, :user_teams, :sprint_timelines, :contributors, :sprint_states, :sprints, :sprint_states, :projects
        context "valid team_id" do
            before(:each) do                    
                get "/user-teams/#{user_teams(:adam_admin_adam_admin_team).team_id}/team-contributors-received?seat_id=#{user_teams(:adam_admin_adam_admin_team).seat_id}", nil, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                @res = JSON.parse(last_response.body)                               
                @result = @mysql_client.query("SELECT count(distinct(sprint_timelines.id)) as count, users.id as id FROM `sprint_timelines` LEFT JOIN contributors ON (sprint_timelines.contributor_id = contributors.id AND sprint_timelines.notification_id=#{notifications(:winner).id}) RIGHT JOIN users ON (users.id = contributors.user_id) INNER JOIN user_teams ON user_teams.user_id = users.id WHERE (sprint_timelines.notification_id=#{notifications(:winner).id} OR sprint_timelines.notification_id IS NULL) AND `user_teams`.`seat_id` = #{user_teams(:adam_admin_adam_admin_team).seat_id} AND `user_teams`.`team_id` = #{user_teams(:adam_admin_adam_admin_team).team_id} GROUP BY users.id")
            end                                                                                                 
            it_behaves_like "team-aggregates"               
        end        
        context "not member" do
            fixtures :seats 
            before(:each) do
                @mysql_client.query("update user_teams set seat_id = #{seats(:sponsored).id} where id = #{user_teams(:adam_confirmed_adam_admin_team).id}")
                get "/user-teams/#{user_teams(:adam_admin_adam_admin_team).team_id}/team-contributors-received?seat_id=#{user_teams(:adam_admin_adam_admin_team).seat_id}", nil, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
            end 
            it_behaves_like "not_found"
        end 
    end   
end

require_relative '../spec_helper'

describe ".Activity" do
    fixtures :notifications

    before(:each) do
        @activity = Activity.new
    end

    shared_examples_for "user_notifications" do
        it "should return a result" do
            expect(@res.length).to be > 0
        end
        it "should return user_id" do
            expect(@notification_results.count).to be > 0
            @notification_results.each_with_index do |result,i|
                expect(@res[i][:user_id]).to eq result["user_id"]
            end
        end
    end

    context "#user_notifications_for_owner" do
        fixtures :users, :sprints, :sprint_timelines, :sprint_states, :comments
        before(:each) do
            @sprint_timeline_id = sprint_timelines(:sprint_1_state_1_comment).id
            @notification_results = [{"user_id" => decrypt(sprint_timelines(:sprint_1_state_1_comment).sprint.user.id).to_i}]
            @res = @activity.user_notifications_for_owner @sprint_timeline_id
        end
        it_behaves_like "user_notifications"
    end

    context "#user_notifications_for_contributors_with_winner" do
        fixtures :users, :sprints, :sprint_timelines, :sprint_states, :contributors
        before(:each) do
            @sprint_timeline_id = sprint_timelines(:sprint_1_state_1_winner).id
            @notification_results = @mysql_client.query("select * from contributors where sprint_state_id = #{sprint_states(:sprint_1_state_1).id} AND contributors.user_id != #{decrypt(sprint_timelines(:sprint_1_state_1_winner).user.id).to_i}")
            @res = @activity.user_notifications_for_contributors_with_winner @sprint_timeline_id
        end
        it_behaves_like "user_notifications"
    end

    context "#user_notifications_for_contributor" do
        fixtures :users, :sprints, :sprint_timelines, :sprint_states, :contributors
        context "comment" do
            before(:each) do
                @sprint_timeline_id = sprint_timelines(:sprint_1_state_1_comment).id
                @notification_results = @mysql_client.query("select #{@sprint_timeline_id} as sprint_timeline_id,contributors.user_id from contributors where contributors.id = #{sprint_timelines(:sprint_1_state_1_comment).contributor.id} AND (contributors.user_id != #{decrypt(sprint_timelines(:sprint_1_state_1_comment).user.id).to_i})")
                @res = @activity.user_notifications_for_contributor @sprint_timeline_id
            end
            it_behaves_like "user_notifications"
        end
        context "vote" do
            before(:each) do
                @sprint_timeline_id = sprint_timelines(:sprint_1_state_1_vote).id 
                @notification_results = @mysql_client.query("select #{@sprint_timeline_id} as sprint_timeline_id,contributors.user_id from contributors where contributors.id = #{sprint_timelines(:sprint_1_state_1_vote).contributor.id} AND (contributors.user_id != #{decrypt(sprint_timelines(:sprint_1_state_1_vote).user.id).to_i})")
                @res = @activity.user_notifications_for_contributor @sprint_timeline_id
            end                                                     
            it_behaves_like "user_notifications"
        end
    end

    context "#user_notifications_by_comments" do
        fixtures :users, :sprints, :sprint_timelines, :sprint_states, :contributors, :comments
        before(:each) do
            @sprint_timeline_id = sprint_timelines(:sprint_1_state_1_winner).id 
            @notification_results = @mysql_client.query("select #{@sprint_timeline_id} as sprint_timeline_id,comments.user_id from comments join contributors on comments.contributor_id = contributors.id join users on comments.user_id = users.id where users.id != #{decrypt(sprint_timelines(:sprint_1_state_1_winner).user.id).to_i}")
            @res = @activity.user_notifications_by_comments @sprint_timeline_id
        end                                                     
        it_behaves_like "user_notifications"
    end

    context "#user_notifications_by_votes" do
        fixtures :users, :sprints, :sprint_timelines, :sprint_states, :contributors, :votes
        before(:each) do
            @sprint_timeline_id = sprint_timelines(:sprint_1_state_1_winner).id 
            @notification_results = @mysql_client.query("select #{@sprint_timeline_id} as sprint_timeline_id,votes.user_id from votes join contributors on votes.contributor_id = contributors.id join users on votes.user_id = users.id where users.id != #{decrypt(sprint_timelines(:sprint_1_state_1_winner).user.id).to_i}")
            @res = @activity.user_notifications_by_votes @sprint_timeline_id
        end                                                     
        it_behaves_like "user_notifications"
    end

    context "#user_notifications_by_roles" do
        fixtures :users, :sprints, :sprint_timelines, :sprint_states, :roles, :user_roles, :states, :role_states
        before(:each) do
            @sprint_timeline_id = sprint_timelines(:sprint_1_transition).id 
            @notification_results = @mysql_client.query("select #{@sprint_timeline_id} as sprint_timeline_id, users.id as user_id from users join user_roles on users.id = user_roles.user_id join role_states where (user_roles.user_id != #{decrypt(sprint_timelines(:sprint_1_transition).user_id).to_i}) AND user_roles.role_id = role_states.role_id AND role_states.id = #{role_states(:product_requirements_design).id}")
            @res = @activity.user_notifications_by_roles @sprint_timeline_id
        end
        it_behaves_like "user_notifications"
    end

    context "#user_notifications_for_job" do
        fixtures :users, :jobs, :sprint_timelines, :roles, :user_roles
        before(:each) do
            @sprint_timeline_id = sprint_timelines(:job_developer).id
            @notification_results = @mysql_client.query("select #{@sprint_timeline_id} as sprint_timeline_id, user_roles.user_id as user_id from jobs INNER JOIN sprint_timelines ON sprint_timelines.job_id = jobs.id INNER JOIN user_roles ON user_roles.role_id = jobs.role_id AND user_roles.active = 1 where (user_roles.user_id != #{decrypt(sprint_timelines(:job_developer).user_id).to_i}) and sprint_timelines.id = #{@sprint_timeline_id}")
            @res = @activity.user_notifications_for_job @sprint_timeline_id
        end
        it_behaves_like "user_notifications"
    end

    context "#user_notifications_for_job_owner" do
        fixtures :users, :jobs, :sprint_timelines
        before(:each) do
            @sprint_timeline_id = sprint_timelines(:job_developer_idea).id
            @notification_results = @mysql_client.query("select #{@sprint_timeline_id} as sprint_timeline_id, jobs.user_id as user_id from jobs INNER JOIN sprint_timelines ON sprint_timelines.job_id = jobs.id where sprint_timelines.id = #{@sprint_timeline_id}")
            @res = @activity.user_notifications_for_job_owner @sprint_timeline_id
        end
        it_behaves_like "user_notifications"
    end

    context "#user_notifications_for_job_contributors" do
        fixtures :users, :jobs, :sprint_timelines, :sprints
        before(:each) do
            @sprint_timeline_id = sprint_timelines(:job_developer_idea).id
            @notification_results = @mysql_client.query("select #{@sprint_timeline_id} as sprint_timeline_id, sprints.user_id as user_id from sprints INNER JOIN sprint_timelines ON sprint_timelines.job_id = sprints.job_id where sprint_timelines.id = #{sprint_timelines(:job_developer_idea).id}")
            @res = @activity.user_notifications_for_job_contributors @sprint_timeline_id
        end
        it_behaves_like "user_notifications"
    end

    context "#record_user_notifications" do
        fixtures :users, :sprints, :sprint_timelines
        before(:each) do
            @bulk = [{:user_id => decrypt(users(:adam_confirmed).id).to_i, :sprint_timeline_id => sprint_timelines(:sprint_1_transition).id}] 
            @res = @activity.record_user_notifications @bulk
            @result = @mysql_client.query("select * from user_notifications")
        end
        it "should return true" do
            expect(@res).to be true
        end
        context "bulk" do
            it "should save all records" do
                expect(@result.count).to eq @bulk.length
            end
            it "should save sprint_timeline_id" do
                @result.each_with_index do |r,i|
                    expect(r["sprint_timeline_id"]).to eq(@bulk[i][:sprint_timeline_id])
                end
            end
            it "should save user_id" do
                @result.each_with_index do |r,i|
                    expect(r["user_id"]).to eq(@bulk[i][:user_id])
                end 
            end
        end
    end

    context "#store_user_notifications_count" do
        fixtures :users, :sprints, :sprint_timelines
        ["processed","processing"].each do |state|
            before(:each) do
                @value = 30
                @res = @activity.store_user_notifications_count sprint_timelines(:sprint_1_transition).id, @value, state
                @result = @mysql_client.query("select * from sprint_timelines where id = #{sprint_timelines(:sprint_1_transition).id}").first
            end
            it "should return true" do
                expect(@res).to be true
            end
            context "sprint_timelines" do
                it "should set #{state} to value" do
                    expect(@result[state]).to eq @value
                end
            end
        end
    end

    context "#process_notification" do
        fixtures :users, :sprints, :sprint_timelines, :sprint_states, :comments
        before(:each) do #same scenario as #user_notifications_for_owner
            @sprint_timeline_id = sprint_timelines(:sprint_1_state_1_comment).id
            @res = @activity.process_notification @sprint_timeline_id
            @sprint_timeline_result = @mysql_client.query("select * from sprint_timelines where id = #{@sprint_timeline_id}").first
            @user_notifications_result = @mysql_client.query("select * from user_notifications where sprint_timeline_id = #{@sprint_timeline_id}").first
        end
        it "should return true" do
            expect(@res).to be true
        end
        context "sprint_timelines" do
            it "should return processing" do
                expect(@sprint_timeline_result["processing"]).to eq 1 # 1 owner
            end
            it "should return processed" do
                expect(@sprint_timeline_result["processed"]).to eq 1 # 1 owner
            end
        end
        context "user_notifications" do
            it "should return owner" do
                expect(@user_notifications_result["user_id"]).to eq(decrypt(sprint_timelines(:sprint_1_state_1_comment).sprint.user.id).to_i)
            end
            it "should return sprint_timeline_id" do
                expect(@user_notifications_result["sprint_timeline_id"]).to eq @sprint_timeline_id
            end
        end
    end

    context "#get_decrypted_user_ids" do
        fixtures :users
        before(:each) do
            @users = User.all.select("id as user_id")
            @user_ids = [User.first[:id]]
            @res = @activity.get_decrypted_user_ids @users, @user_ids
        end
        it "should return distinct ids" do
            sql = @mysql_client.query("select id from users")
            ids = []
            sql.each_with_index do |s,i|
                ids[i] = s["id"]
            end
            expect(@res.sort).to eq(ids.sort)
        end
    end

    context "#rebuild_users" do
        before(:each) do
            @user_ids = [1,3,9]
            @sprint_timeline_id = 28
            @res = @activity.rebuild_users @user_ids, @sprint_timeline_id 
        end
        it "should return a result" do
            expect(@res.length).to eq @user_ids.length
        end
        it "should return user_id key" do
            @res.each_with_index do |r,i|
                expect(@res[i][:user_id]).to eq(@user_ids[i])
            end
        end
        it "should return sprint_timeline_id key" do
            @res.each_with_index do |r,i|
                expect(@res[i][:sprint_timeline_id]).to eq(@sprint_timeline_id)
            end 
        end
    end

    context "#user_notifications_that_need_to_be_mailed" do
        fixtures :users, :sprint_timelines, :user_notifications, :user_notification_settings, :notifications
        before(:each) do
            @sprint_timeline_id = sprint_timelines(:sprint_1_state_1_winner).id 
            @notification_results = @mysql_client.query("SELECT user_notifications.user_id, user_notifications.sprint_timeline_id FROM user_notifications INNER JOIN sprint_timelines on sprint_timelines.id=user_notifications.sprint_timeline_id INNER JOIN user_notification_settings on user_notification_settings.user_id = user_notifications.user_id INNER JOIN notifications on sprint_timelines.notification_id = notifications.id WHERE (user_notification_settings.active = 1 and user_notification_settings.notification_id = sprint_timelines.notification_id and user_notifications.read = 0 and notifications.name in ('comment', 'transition', 'winner', 'new') and sprint_timelines.id = #{@sprint_timeline_id})").first
            @res = @activity.user_notifications_that_need_to_be_mailed @sprint_timeline_id
            @res.each do |n|
                @user = n[:user_id]
            end
        end                                                   
        context "user_notifications" do
            it "should return owner" do
                expect(@notification_results["user_id"]).to eq(@user)
            end
            it "should return sprint_timeline_id" do
                expect(@notification_results["sprint_timeline_id"]).to eq @sprint_timeline_id
            end
        end
    end
end

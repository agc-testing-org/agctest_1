require_relative '../spec_helper'

describe ".Issue" do
    before(:each) do
        @issue = Issue.new
    end
    context "#create" do
        #covered by API test
    end
    context "#create_project" do
        #covered by API test
    end 
    context "#create_sprint_state" do
        #covered by API test
    end
    context "#get_projects" do
        #covered by API test
    end
    context "#get_sprints" do
        #covered by API test
    end
    context "#get_sprint" do
        #covered by API test
    end
    context "#log_event" do
        #covered by API test
    end
    context "#get_states" do
        fixtures :states
        context "state exists" do
            it "should return state" do
                query = {:id => states(:development).id}
                expect((@issue.get_states query)[0]["name"]).to eq(states(:development).name)
            end
        end
        context "state does not exist" do
            it "should return nil" do
                query = {:id => 1000}
                expect((@issue.get_states query)[0]).to be nil
            end
        end
    end
    context "#get_skillsets" do
        fixtures :skillsets
        context "skillsets" do
            before(:each) do
                @res = @issue.get_skillsets
            end
            it "should include name" do
                expect(@res[0]["name"]).to eq(skillsets(:skillset_1).name)
            end
            it "should include id" do
                expect(@res[0]["id"]).to eq(skillsets(:skillset_1).id)
            end
        end
    end 

    context "#get_sprint_state" do
        fixtures :sprints, :sprint_states, :states
        context "state exists" do
            it "should return sprint state object" do
                expect(@issue.get_sprint_state sprint_states(:sprint_1_state_1).id).to eq(sprint_states(:sprint_1_state_1))
            end
            it "should return state object" do
                expect((@issue.get_sprint_state sprint_states(:sprint_1_state_1).id).state.id).to eq(sprint_states(:sprint_1_state_1).state_id)
            end
        end 
    end 

    shared_examples_for "user_notifications" do
        it "should return a result" do
            expect(@res.length).to be > 0
        end
        it "should return sprint_timeline_id" do
            @res.each_with_index do |result|
                expect(result["id"]).to eq @sprint_timeline_id
            end
        end
        it "should return user_id" do
            expect(@notification_results.count).to be > 0
            @notification_results.each_with_index do |result,i|
                expect(@res[i].user_id).to eq result["user_id"]
            end
        end
    end

    context "#user_notifications_for_owner" do
        fixtures :users, :sprints, :sprint_timelines, :sprint_states, :comments
        before(:each) do
            @sprint_timeline_id = sprint_timelines(:sprint_1_state_1_comment).id
            @notification_results = [{"user_id" => sprint_timelines(:sprint_1_state_1_comment).sprint.user.id}]
            @res = @issue.user_notifications_for_owner @sprint_timeline_id
        end
        it_behaves_like "user_notifications"
    end

    context "#user_notifications_for_contributors_with_winner" do
        fixtures :users, :sprints, :sprint_timelines, :sprint_states, :contributors
        before(:each) do
            @sprint_timeline_id = sprint_timelines(:sprint_1_state_1_winner).id
            @notification_results = @mysql_client.query("select * from contributors where sprint_state_id = #{sprint_states(:sprint_1_state_1).id} AND contributors.user_id != #{sprint_timelines(:sprint_1_state_1_winner).user.id}")
            @res = @issue.user_notifications_for_contributors_with_winner @sprint_timeline_id
        end
        it_behaves_like "user_notifications"
    end

    context "#user_notifications_for_contributor" do
        fixtures :users, :sprints, :sprint_timelines, :sprint_states, :contributors
        context "comment" do
            before(:each) do
                @sprint_timeline_id = sprint_timelines(:sprint_1_state_1_comment).id
                @notification_results = @mysql_client.query("select #{@sprint_timeline_id} as id,contributors.user_id from contributors where contributors.id = #{sprint_timelines(:sprint_1_state_1_comment).contributor.id} AND (contributors.user_id != #{sprint_timelines(:sprint_1_state_1_comment).user.id})")
                @res = @issue.user_notifications_for_contributor @sprint_timeline_id
            end
            it_behaves_like "user_notifications"
        end
        context "vote" do
            before(:each) do
                @sprint_timeline_id = sprint_timelines(:sprint_1_state_1_vote).id 
                @notification_results = @mysql_client.query("select #{@sprint_timeline_id} as id,contributors.user_id from contributors where contributors.id = #{sprint_timelines(:sprint_1_state_1_vote).contributor.id} AND (contributors.user_id != #{sprint_timelines(:sprint_1_state_1_vote).user.id})")
                @res = @issue.user_notifications_for_contributor @sprint_timeline_id
            end                                                     
            it_behaves_like "user_notifications"
        end
    end

    context "#user_notifications_by_comments" do
        fixtures :users, :sprints, :sprint_timelines, :sprint_states, :contributors, :comments
        before(:each) do
            @sprint_timeline_id = sprint_timelines(:sprint_1_state_1_winner).id 
            @notification_results = @mysql_client.query("select #{@sprint_timeline_id} as id,comments.user_id from comments join contributors on comments.contributor_id = contributors.id join users on comments.user_id = users.id where users.id != #{sprint_timelines(:sprint_1_state_1_winner).user.id}")
            @res = @issue.user_notifications_by_comments @sprint_timeline_id
        end                                                     
        it_behaves_like "user_notifications"
    end

    context "#user_notifications_by_votes" do
        fixtures :users, :sprints, :sprint_timelines, :sprint_states, :contributors, :votes
        before(:each) do
            @sprint_timeline_id = sprint_timelines(:sprint_1_state_1_winner).id 
            @notification_results = @mysql_client.query("select #{@sprint_timeline_id} as id,votes.user_id from votes join contributors on votes.contributor_id = contributors.id join users on votes.user_id = users.id where users.id != #{sprint_timelines(:sprint_1_state_1_winner).user.id}")
            @res = @issue.user_notifications_by_votes @sprint_timeline_id
        end                                                     
        it_behaves_like "user_notifications"
    end

    context "#user_notifications_by_roles" do
        fixtures :users, :sprints, :sprint_timelines, :sprint_states, :roles, :user_roles, :states, :role_states
        before(:each) do
            @sprint_timeline_id = sprint_timelines(:sprint_1_transition).id 
            @notification_results = @mysql_client.query("select #{@sprint_timeline_id} as id, users.id as user_id from users join user_roles on users.id = user_roles.user_id join role_states where user_roles.role_id = role_states.role_id AND role_states.id = #{role_states(:product_requirements_design).id}")
            @res = @issue.user_notifications_by_roles @sprint_timeline_id
        end
        it_behaves_like "user_notifications"
    end
end

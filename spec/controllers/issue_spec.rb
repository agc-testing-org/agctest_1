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
                query = {:id => states(:backlog).id}
                expect((@issue.get_states query)[0]["name"]).to eq(states(:backlog).name)
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

    context "#last_event" do
        fixtures :sprint_timelines
        context "after exists" do
            it "should return id of last event" do
                expect(@issue.last_event sprint_timelines(:demo_6).sprint_id).to eq(sprint_timelines(:demo_6).id) #return the last event for a sprint...demo_2 is last
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

=begin
    context "#create_entry_in_notifications_table", :focus => true do
        fixtures :sprint_timelines, :notifications
        context "create_entry" do
            before(:each) do
                @res = @issue.recently_changed_sprint?
                puts @res
                @state_change_notification = @mysql_client.query("select * from notifications where subject='Sprint State Change'").first
                @comment_notification = @mysql_client.query("select * from notifications where subject='New Comment'").first
                @vote_notification = @mysql_client.query("select * from notifications where subject='New Vote'").first

            end
            context "notifications count vs sprint_timelines count" do
                it "should be eq" do
                    expect(@mysql_client.query("select count(*) from sprint_timelines").first).to eq(@mysql_client.query("select count(*) from notifications").first)
                end
            end

            context "entry for sprint state change" do
                it "should include sprint_id" do
                    expect(@state_change_notification["sprint_id"]).to eq(sprint_timelines(:demo_1).sprint_id)
                end
                it "should include sprint_state_id" do
                    expect(@state_change_notification["sprint_state_id"]).to eq(sprint_timelines(:demo_1).state_id)
                end
                it "should include user_id" do
                    expect(@state_change_notification["user_id"]).to eq(sprint_timelines(:demo_1).user_id)
                end
                it "should include sprint_timeline_id" do
                    expect(@state_change_notification["sprint_timeline_id"]).to eq(sprint_timelines(:demo_1).id)
                end
                it "should include contributor_id" do
                    expect(@state_change_notification["contributor_id"]).to eq(sprint_timelines(:demo_1).contributor_id)
                end
                it "should include subject" do
                    expect(@state_change_notification["subject"]).to eq("Sprint State Change")
                end
                it "should include body" do
                    expect(@state_change_notification["body"]).to eq("Sprint state changed")
                end
            end
            context "entry for sprint comment" do
                it "should include sprint_id" do
                    expect(@comment_notification["sprint_id"]).to eq(sprint_timelines(:demo_5).sprint_id)
                end
                it "should include sprint_state_id" do
                    expect(@comment_notification["sprint_state_id"]).to eq(sprint_timelines(:demo_5).state_id)
                end
                it "should include user_id" do
                    expect(@comment_notification["user_id"]).to eq(sprint_timelines(:demo_5).user_id)
                end
                it "should include sprint_timeline_id" do
                    expect(@comment_notification["sprint_timeline_id"]).to eq(sprint_timelines(:demo_5).id)
                end
                it "should include contributor_id" do
                    expect(@comment_notification["contributor_id"]).to eq(sprint_timelines(:demo_5).contributor_id)
                end
                it "should include subject" do
                    expect(@comment_notification["subject"]).to eq("New Comment")
                end
                it "should include body" do
                    expect(@comment_notification["body"]).to eq("Sprint commented")
                end
            end
            context "entry for sprint vote" do
                it "should include sprint_id" do
                    expect(@vote_notification["sprint_id"]).to eq(sprint_timelines(:demo_6).sprint_id)
                end
                it "should include sprint_state_id" do
                    expect(@vote_notification["sprint_state_id"]).to eq(sprint_timelines(:demo_6).state_id)
                end
                it "should include user_id" do
                    expect(@vote_notification["user_id"]).to eq(sprint_timelines(:demo_6).user_id)
                end
                it "should include sprint_timeline_id" do
                    expect(@vote_notification["sprint_timeline_id"]).to eq(sprint_timelines(:demo_6).id)
                end
                it "should include contributor_id" do
                    expect(@vote_notification["contributor_id"]).to eq(sprint_timelines(:demo_6).contributor_id)
                end
                it "should include subject" do
                    expect(@vote_notification["subject"]).to eq("New Vote")
                end
                it "should include body" do
                    expect(@vote_notification["body"]).to eq("Sprint voted")
                end
            end
        end
    end 

    context "#create_entry_in_user_notifications_table" do
        fixtures :notifications, :users, :sprint_skillsets, :user_skillsets, :user_roles, :user_contributors
        context "create_entry" do
            before(:each) do
                @res = (@issue.create_user_notification)
                puts @res
                @skillset_notification =  @mysql_client.query("select * from user_notifications where notifications_id=1").first
                @roles_notification_product =  @mysql_client.query("select * from user_notifications where notifications_id=2").first
                @roles_notification_design =  @mysql_client.query("select * from user_notifications where notifications_id=3 ORDER BY ID DESC").first
                @roles_notification_development =  @mysql_client.query("select * from user_notifications where notifications_id=4 ORDER BY ID DESC").first
                @comment_notification =  @mysql_client.query("select * from user_notifications where notifications_id=5").first
                @votes_notification =  @mysql_client.query("select * from user_notifications where notifications_id=6").first
                puts @skillset_notification


            end
            context "skillset_notification" do
                it "should include user_id" do
                    expect(@skillset_notification["user_id"]).to eq(users(:masha_post_connection_request).id)
                end
                it "should include notification_id" do
                    expect(@skillset_notification["notifications_id"]).to eq(notifications(:skillset_notification).id)
                end
            end
            context "roles_notification_product" do
                it "should include user_id" do
                    expect(@roles_notification_product["user_id"]).to eq(users(:masha_post_connection_request).id)
                end
                it "should include notification_id" do
                    expect(@roles_notification_product["notifications_id"]).to eq(notifications(:roles_notification_product).id)
                end
            end
            context "roles_notification_design" do
                it "should include user_id" do
                    expect(@roles_notification_design["user_id"]).to eq(users(:masha_get_connection_request).id)
                end
                it "should include notification_id" do
                    expect(@roles_notification_design["notifications_id"]).to eq(notifications(:roles_notification_design).id)
                end
            end
            context "roles_notification_development" do
                it "should include user_id" do
                    expect(@roles_notification_development["user_id"]).to eq(users(:masha_notifications).id)
                end
                it "should include notification_id" do
                    expect(@roles_notification_development["notifications_id"]).to eq(notifications(:roles_notification_development).id)
                end
            end
            context "roles_notification_comment" do
                it "should include user_id" do
                    expect(@comment_notification["user_id"]).to eq(users(:masha_get_connection_request).id)
                end
                it "should include notification_id" do
                    expect(@comment_notification["notifications_id"]).to eq(notifications(:comments_notification).id)
                end
            end
            context "roles_notification_vote" do
                it "should include user_id" do
                    expect(@votes_notification["user_id"]).to eq(users(:masha_get_connection_request).id)
                end
                it "should include notification_id" do
                    expect(@votes_notification["notifications_id"]).to eq(notifications(:votes_notification).id)
                end
            end
        end
    end 
=end
end

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

    context "#get_user_connections" do
        fixtures :users
        context "connections" do
            fixtures :user_connections
            before(:each) do
                user_id = users(:masha_get_connection_request).id
                query = {"user_connections.contact_id" => user_id}
                @res = (@issue.get_user_connections query).first
            end
            it "should include user_id" do
                expect(@res["user_id"]).to eq(users(:masha_post_connection_request).id)
            end
            it "should include contact_id" do
                expect(@res["contact_id"]).to eq(users(:masha_get_connection_request).id)
            end
            it "should include read" do
                expect(@res["read"]).to eq(user_connections(:user_2_connection_1).read)
            end
            it "should include confirmed" do
                expect(@res["confirmed"]).to eq(user_connections(:user_2_connection_1).confirmed)
            end
            it "should include user_name" do
                expect(@res["user_name"]).to eq(users(:masha_post_connection_request).name)
            end
        end
    end 

    context "#get_user_info", :focus => true do
        fixtures :users
        context "user_info" do
            fixtures :user_connections
            before(:each) do
                user_id = users(:masha_post_connection_request).id
                @res = (@issue.get_user_info user_id).first
            end
            it "should include user_id" do
                expect(@res["first_name"]).to eq(users(:masha_get_connection_request).first_name)
            end
            it "should include contact_id" do
                expect(@res["email"]).to eq(users(:masha_get_connection_request).email)
            end
        end
    end 

    context "#patch_user_connections_read" do
        fixtures :users
        context "connection_request_read" do
            fixtures :user_connections
            before(:each) do
                contact_id = (users(:masha_get_connection_request).id)
                user_id = (users(:masha_post_connection_request).id)
                @read = false
                @res = (@issue.update_user_connections_read contact_id, user_id, @read)
            end
            it "should include read" do
                expect(@res[:read]).to eq(@read)
            end
        end
    end 

    context "#patch_user_connections_confirmed" do
        fixtures :users
        context "connection_request_confirmed" do
            fixtures :user_connections
            before(:each) do
                contact_id = (users(:masha_get_connection_request).id)
                user_id = (users(:masha_post_connection_request).id)
                @confirmed = 3
                @res = (@issue.update_user_connections_confirmed contact_id, user_id, @confirmed)
            end
            it "should include read" do
                expect(@res[:confirmed]).to eq(@confirmed)
            end
        end
    end 

    context "#post_user_connections_request" do
        fixtures :users
        context "connection_request_confirmed" do
            fixtures :user_connections
            before(:each) do
                @contact_id = (users(:adam_protected).id)
                @user_id = (users(:adam).id)
                @res = (@issue.create_connection_request @user_id, @contact_id)
            end
            it "should include user_id" do
                expect(@res["user_id"]).to eq(@user_id)
            end
            it "should include contact_id" do
                expect(@res["contact_id"]).to eq(@contact_id)
            end
            it "should include read" do
                expect(@res["read"]).to eq(false)
            end
            it "should include confirmed" do
                expect(@res["confirmed"]).to eq(1)
            end
        end
    end 


=begin
    context "#create_entry_in_notifications_table", :focus => true do
        fixtures :sprint_timelines
        context "create_entry" do
            before(:each) do
                @res = (@issue.recently_changed_sprint?)
                @state_change_notification = @mysql_client.query("select * from notifications where subject='Sprint state changed'").first
                @comment_notification = @mysql_client.query("select * from notifications where subject='Sprint commented'").first
                @vote_notification = @mysql_client.query("select * from notifications where subject='Sprint voted'").first

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
                    expect(@state_change_notification["subject"]).to eq("Sprint state changed")
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
                    expect(@comment_notification["subject"]).to eq("Sprint commented")
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
                    expect(@vote_notification["subject"]).to eq("Sprint voted")
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
                @skillset_notification =  @mysql_client.query("select * from user_notifications where notifications_id=1").first
                @roles_notification_product =  @mysql_client.query("select * from user_notifications where notifications_id=2").first
                @roles_notification_design =  @mysql_client.query("select * from user_notifications where notifications_id=3 ORDER BY ID DESC").first
                @roles_notification_development =  @mysql_client.query("select * from user_notifications where notifications_id=4 ORDER BY ID DESC").first
                @comment_notification =  @mysql_client.query("select * from user_notifications where notifications_id=5").first
                @votes_notification =  @mysql_client.query("select * from user_notifications where notifications_id=6").first


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

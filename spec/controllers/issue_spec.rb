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
        # NOT COVERED 
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
    context "#get_skillsets", :focus => true do
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
                expect(@issue.last_event sprint_timelines(:demo_2).sprint_id).to eq(sprint_timelines(:demo_2).id) #return the last event for a sprint...demo_2 is last
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
end

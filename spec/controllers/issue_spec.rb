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
    context "#get_sprint_state_ids_by_sprint" do
        fixtures :sprints, :sprint_states
        it "should return a list of all sprint_state_ids" do
            expect(@issue.get_sprint_state_ids_by_sprint sprint_states(:sprint_1_state_1).id).to eq(@mysql_client.query("select id from sprint_states where sprint_id = #{sprint_states(:sprint_1_state_1).id} ORDER BY created_at ASC").to_a)
        end
    end
    context "#get_next_sprint_state" do
        before(:each) do
            @list = [1,3,9,44]
        end
        it "should return the next item in the list" do
            expect(@issue.get_next_sprint_state @list[1], @list).to eq(@list[2])
        end
    end
end

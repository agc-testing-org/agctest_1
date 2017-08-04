require 'spec_helper'
require 'api_helper'

describe "/sprints" do

    fixtures :users, :projects, :states, :seats, :notifications

    before(:all) do
        @CREATE_TOKENS=true
    end 

    shared_examples_for "sprints" do
        it "should return id" do
            @sprint_results.each_with_index do |sprint_result,i|
                expect(@sprints[i]["id"]).to eq(sprint_result["id"])
            end
        end
        if @include_project
            it "should return project (id)" do
                @sprint_results.each_with_index do |sprint_result,i|
                    expect(@sprints[i]["project"]).to eq(sprint_result["project_id"])
                end                                         
            end 
        end
        it "should return user_id" do
            @sprint_results.each_with_index do |sprint_result,i|
                expect(decrypt(@sprints[i]["user_id"]).to_i).to eq(sprint_result["user_id"])
            end
        end
        it "should return title" do
            @sprint_results.each_with_index do |sprint_result,i|
                expect(@sprints[i]["title"]).to eq(sprint_result["title"])
            end
        end
        it "should return description" do
            @sprint_results.each_with_index do |sprint_result,i|
                expect(@sprints[i]["description"]).to eq(sprint_result["description"])
            end
        end
        it "should return sha" do
            @sprint_results.each_with_index do |sprint_result,i|
                expect(@sprints[i]["sha"]).to eq(sprint_result["sha"])
            end
        end
        it "should return winner_id" do
            @sprint_results.each_with_index do |sprint_result,i|
                expect(@sprints[i]["winner_id"]).to eq(sprint_result["winner_id"])
            end
        end
    end

    shared_examples_for "sprint_states" do
        it "should include sprint_id" do
            expect(@sprint_state["sprint_id"]).to eq @sprints[0]["id"]
        end
        it "should include idea state_id" do
            expect(@sprint_state["state_id"]).to eq(states(:idea).id)
        end
    end

    shared_examples_for "sprint_timelines" do
        it "should include sprint_id" do
            expect(@timeline["sprint_id"]).to eq(@sprints[0]["id"])
        end                                                                     
        it "should include idea state_id" do            
            expect(@timeline["state_id"]).to eq(states(:idea).id)               
        end                                                                                     
        it "should include sprint_state_id" do                          
            expect(@timeline["sprint_state_id"]).to eq(1)                                       
        end   
    end

    shared_examples_for "sprint_skillsets" do 
        context "all" do
            it "should return all skillsets" do
                expect(@res.length).to eq(Skillset.count)
                Skillset.all.each_with_index do |skillset,i|           
                    expect(@res[i]["name"]).to eq(skillset.name)                               
                end                                                                                            
            end                                                                    
        end                                
        context "sprint skillsets" do
            it "should include active" do  
                @res.each do |skillset|                        
                    if SprintSkillset.count > 0                                        
                        if skillset["id"] == sprint_skillsets(:sprint_1_skillset_1).id                             
                            expect(skillset["active"]).to eq(sprint_skillsets(:sprint_1_skillset_1).active)                                        
                        end                                                                                                                                                
                    end                                                                                                                
                end                                                                                    
            end                                                            
        end                                        
    end 

    shared_examples_for "sprint_skillset_update" do
        context "response" do
            it "should return skillset_id as id" do
                expect(@res["id"]).to eq(@skillset_id)
            end
        end
        context "sprint_skillset" do
            it "should include most recent active" do
                expect(@mysql["active"]).to eq(@active ? 1 : 0)
            end
        end
    end

    describe "POST /" do
        before(:each) do
            @title = "SPRINT TITLE"
            @description = "SPRINT DESCRIPTION"
            @project_id = projects(:demo).id
            @sha = "SHA"
        end
        context "invalid fields" do
            after(:each) do
                expect(@mysql_client.query("select * from sprints").count).to eq 0
            end
            context "title < 5 chars" do
                before(:each) do 
                    post "sprints", {:title => "A"*4, :description => @description, :project_id => @project_id }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                end
                it_behaves_like "error", "title must be 5-100 characters" 

            end
            context "title > 100 chars" do
                before(:each) do 
                    post "sprints", {:title => "A"*101, :description => @description, :project_id => @project_id }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                end
                it_behaves_like "error", "title must be 5-100 characters"

            end
            context "description < 5 chars" do
                before(:each) do 
                    post "sprints", {:title => @title, :description => "A"*4, :project_id => @project_id }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                end
                it_behaves_like "error", "description must be 5-500 characters"

            end
            context "description > 500 chars" do
                before(:each) do 
                    post "sprints", {:title => @title, :description => "A"*501, :project_id => @project_id }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                end
                it_behaves_like "error", "description must be 5-500 characters"

            end
            context "non-existing project" do
                before(:each) do 
                    post "sprints", {:title => @title, :description => @description, :project_id => 993 }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                end
                it_behaves_like "error", "unable to create sprint for this project"

            end
        end
        context "valid fields" do
            context "without job_id" do
                before(:each) do
                    post "sprints", {:title => @title, :description => @description, :project_id => @project_id }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                    @sprint_results = @mysql_client.query("select * from sprints")
                    @sprint_state = @mysql_client.query("select * from sprint_states").first
                    @timeline = @mysql_client.query("select * from sprint_timelines where sprint_id = #{@sprint_results.first["id"]}").first
                    @sprints = [JSON.parse(last_response.body)]
                end
                it_behaves_like "sprints"
                it_behaves_like "created"
                it_behaves_like "sprint_states"
                it_behaves_like "sprint_timelines"
            end
            context "with job_id" do
                fixtures :jobs
                before(:each) do
                    @job_id = jobs(:developer).id
                    post "sprints", {:title => @title, :description => @description, :project_id => @project_id, :job_id => @job_id }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                    @sprint_results = @mysql_client.query("select * from sprints")
                    @sprint_state = @mysql_client.query("select * from sprint_states").first
                    @timeline = @mysql_client.query("select * from sprint_timelines where sprint_id = #{@sprint_results.first["id"]}").first
                    @sprints = [JSON.parse(last_response.body)]
                end
                it "should save job_id" do
                    expect(@sprints[0]["job_id"]).to eq(@sprint_results.first["job_id"])
                end
                it_behaves_like "sprints"
                it_behaves_like "created"
                it_behaves_like "sprint_states"
                it_behaves_like "sprint_timelines"
            end
        end
    end

    describe "GET /" do
        fixtures :sprints, :sprint_states
        context "valid params" do
            before(:each) do
                @include_project = true
            end
            context "filter by" do
                context "project_id" do
                    before(:each) do
                        project_id = projects(:demo).id
                        get "/sprints?project_id=#{project_id}"
                        @sprints = JSON.parse(last_response.body)
                        @sprint_results = @mysql_client.query("select sprints.* from sprints INNER JOIN sprint_states ON sprint_states.sprint_id = sprints.id INNER JOIN (SELECT MAX(id) last_id FROM sprint_states GROUP BY sprint_id) last_sprint_state ON sprint_states.id = last_sprint_state.last_id where project_id = #{project_id}")
                    end
                    it_behaves_like "sprints"
                    it_behaves_like "ok"
                end
                context "sprint_states.state_id" do
                    before(:each) do
                        state_id = sprint_states(:sprint_1_state_1).state_id
                        project_id = projects(:demo).id
                        get "/sprints?project_id=#{project_id}&sprint_states.state_id=#{state_id}"
                        @sprints = JSON.parse(last_response.body)
                        @sprint_results = @mysql_client.query("select sprints.* from sprints INNER JOIN sprint_states ON sprint_states.sprint_id = sprints.id INNER JOIN (SELECT MAX(id) last_id FROM sprint_states GROUP BY sprint_id) last_sprint_state ON sprint_states.id = last_sprint_state.last_id where sprint_states.state_id = #{state_id} AND project_id = #{project_id}")
                    end
                    it_behaves_like "sprints"
                    it_behaves_like "ok"
                end
                context "id" do
                    before(:each) do
                        id = sprints(:sprint_1).id
                        get "/sprints?id=#{id}"
                        @sprints = JSON.parse(last_response.body)
                        @sprint_results = @mysql_client.query("select sprints.* from sprints INNER JOIN sprint_states ON sprint_states.sprint_id = sprints.id INNER JOIN (SELECT MAX(id) last_id FROM sprint_states GROUP BY sprint_id) last_sprint_state ON sprint_states.id = last_sprint_state.last_id where sprints.id = #{id}")
                    end
                    it_behaves_like "sprints"
                    it_behaves_like "ok"
                end
            end
        end
    end

    describe "GET /:id" do
        fixtures :sprints, :sprint_states
        before(:each) do
            sprint = sprints(:sprint_1)
            get "/sprints/#{sprint.id}", {}, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
            @sprints = [JSON.parse(last_response.body)]
            @sprint_results = @mysql_client.query("select * from sprints where id = #{sprint.id}")
        end
        it_behaves_like "sprints"
        it_behaves_like "ok"
    end

    describe "GET /:sprint_id/skillsets" do
        fixtures :skillsets, :sprints
        before(:each) do
            @sprint_id = sprints(:sprint_1).id
        end
        context "no sprint_skillsets" do
            before(:each) do
                get "/sprints/#{@sprint_id}/skillsets", {},  {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"} 
                @res = JSON.parse(last_response.body)
            end
            it_behaves_like "sprint_skillsets"
            it_behaves_like "ok"
        end
        context "sprint_skillsets" do
            fixtures :sprint_skillsets
            before(:each) do
                get "/sprints/#{@sprint_id}/skillsets", {},  {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}  
                @res = JSON.parse(last_response.body)
            end 
            it_behaves_like "sprint_skillsets"
            it_behaves_like "ok"
        end

    end

    describe "GET /:sprint_id/skillsets/:skillset_id" do
        fixtures :skillsets, :sprints
        before(:each) do
            @sprint_id = sprints(:sprint_1).id
            @skillset_id = skillsets(:skillset_1).id
        end
        context "no sprint_skillsets" do
            before(:each) do
                get "/sprints/#{@sprint_id}/skillsets/#{@skillset_id}", {},  {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
                @res = [JSON.parse(last_response.body)]
            end
            it_behaves_like "sprint_skillsets"
            it_behaves_like "ok"
        end
        context "sprint_skillsets" do
            fixtures :sprint_skillsets
            before(:each) do
                get "/sprints/#{@sprint_id}/skillsets/#{@skillset_id}", {},  {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
                @res = [JSON.parse(last_response.body)]
            end
            it_behaves_like "sprint_skillsets"
            it_behaves_like "ok"
        end
    end


    describe "PATCH /:sprint_id/skillsets/:skillset_id" do
        fixtures :skillsets, :sprints
        before(:each) do
            @sprint_id = sprints(:sprint_1).id
            @skillset_id = skillsets(:skillset_1).id 
        end
        context "admin" do
            context "skillset exists" do
                fixtures :sprint_skillsets
                before(:each) do
                    @active = false 
                    patch "/sprints/#{@sprint_id}/skillsets/#{@skillset_id}", {:active => @active}.to_json,  {"HTTP_AUTHORIZATION" => "Bearer #{@admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
                    @res = JSON.parse(last_response.body)
                    @mysql = @mysql_client.query("select * from sprint_skillsets where id = #{sprint_skillsets(:sprint_1_skillset_1).id}").first
                end
                it_behaves_like "sprint_skillset_update"
                it_behaves_like "ok"
            end 
            context "skillset does not exist" do
                before(:each) do
                    @active = true
                    patch "/sprints/#{@sprint_id}/skillsets/1221", {:active => @active}.to_json,  {"HTTP_AUTHORIZATION" => "Bearer #{@admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
                    @res = JSON.parse(last_response.body)
                    @mysql = @mysql_client.query("select * from sprint_skillsets").first
                end
                it_behaves_like "error", "unable to update skillset"
            end
        end
        context "non-admin" do
            before(:each) do
                @active = false
                patch "/sprints/#{@sprint_id}/skillsets/#{@skillset_id}", {:active => @active}.to_json,  {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}", "HTTP_AUTHORIZATION_GITHUB" => "Bearer #{@non_admin_github_token}"}
                @res = JSON.parse(last_response.body)
            end
            it_behaves_like "unauthorized_admin"
        end
    end

end

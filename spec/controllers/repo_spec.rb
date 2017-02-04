require_relative '../spec_helper'

describe ".Issue" do
    before(:all) do
        @mysql_client = Mysql2::Client.new(
            :host => ENV['INTEGRATIONS_MYSQL_HOST'],
            :username => ENV['INTEGRATIONS_MYSQL_USERNAME'],
            :password => ENV['INTEGRATIONS_MYSQL_PASSWORD'],
            :database => "integrations_#{ENV['RACK_ENV']}"
        )
        @redis = Redis.new(:host => ENV['INTEGRATIONS_REDIS_HOST'], :port => ENV['INTEGRATIONS_REDIS_PORT'], :db => ENV['INTEGRATIONS_REDIS_DB'])
    end
    before(:each) do
        @repo = Repo.new
    end
    context "#name" do
        it "should return a unique name w/ adjective - color - number" do
            expect(@repo.name.split("-").length).to be >= 2
        end
    end
    context "#create" do
        context "valid sprint_state_id" do
            fixtures :users, :sprint_states, :projects
            before(:each) do 
                @user_id = users(:adam_confirmed).id
                @sprint_state_id = sprint_states(:sprint_1_state_1).id
                @repo_name = "something"
                @project = projects(:demo).id
                @res = @repo.create @user_id, @project, @sprint_state_id, @repo_name
                @sql = @mysql_client.query("select * from contributors").first
            end
            context "contributor" do
                it "should include repo name" do
                    expect(@sql["repo"]).to eq(@repo_name)
                end
                it "should include user_id" do
                    expect(@sql["user_id"]).to eq(@user_id)
                end
                it "should include sprint_state_id" do
                    expect(@sql["sprint_state_id"]).to eq(@sprint_state_id)
                end
            end
            it "should return contributor id" do
                expect(@res).to eq(1)
            end
        end
        context "invalid sprint_state_id" do
            fixtures :users, :projects
            before(:each) do                
                @user_id = users(:adam_confirmed).id
                @project = projects(:demo).id
                @sprint_state_id = 99
                @repo_name = "something"
                @res = @repo.create @user_id, @project, @sprint_state_id, @repo_name
            end         
            it "should return nil" do
                expect(@res).to be nil 
            end
        end
    end
    context "#get_repository" do
        fixtures :users, :projects
        context "repository exists" do           
            fixtures :contributors
            it "should return last contribution" do
                expect(@repo.get_repository users(:adam_confirmed).id, projects(:demo).id).to eq(contributors(:adam_confirmed_1))
            end
        end
        context "repository does not exist" do
            it "should return nil" do
                expect(@repo.get_repository users(:adam_confirmed).id, projects(:demo).id).to eq(nil)
            end
        end
    end
end

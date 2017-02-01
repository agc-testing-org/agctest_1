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
        @issue = Issue.new
    end
    context "#create" do
        #covered by API test
    end
    context "#create_project" do
        #covered by API test
    end 
    context "#get_projects" do
        #covered by API test
    end
    context "#get_sprints" do
        #covered by API test
    end
    context "#log_event" do
        #covered by API test
    end
    context "#get_state_by_name" do
        fixtures :states
        context "state exists" do
            it "should return state by name" do
                expect(@issue.get_state_by_name states(:backlog).name).to eq(states(:backlog).id)
            end
        end
        context "state does not exist" do
            it "should return nil" do
                expect(@issue.get_state_by_name "wrong").to be nil
            end
        end
    end
end

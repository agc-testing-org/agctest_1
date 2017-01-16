require_relative '../spec_helper'

describe "/sprint" do
    fixtures :users, :projects
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
        @user = users(:adam_confirmed).id
        @password = "adam12345"
        @email = users(:adam_confirmed).email
        post "/login", { :password => @password, :email => @email }.to_json
        res = JSON.parse(last_response.body)
        @w7_token = res["w7_token"]
    end

    describe "POST /" do
        before(:each) do
            @title = "SPRINT TITLE" 
            @description = "SPRINT DESCRIPTION"
            @project_id = projects(:demo).id 
            @sha = "SHA"
        end
        context "valid fields" do
            before(:each) do
                post "/sprint", {:title => @title, :description => @description, :project_id => @project_id }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@w7_token}"}
                @mysql = @mysql_client.query("select * from sprints").first
                @res = JSON.parse(last_response.body)
            end
            context "sprint" do
                it "should include title" do
                    expect(@mysql["title"]).to eq(@title)
                end
                it "should include description" do
                    expect(@mysql["description"]).to eq(@description)
                end
                it "should include project_id" do
                    expect(@mysql["project_id"]).to eq(@project_id)
                end
                it "should include user_id" do
                    expect(@mysql["user_id"]).to eq(@user) 
                end
            end
            it "should return sprint id" do
                expect(@res["id"]).to eq(@mysql["id"])  
            end 
        end
    end
end

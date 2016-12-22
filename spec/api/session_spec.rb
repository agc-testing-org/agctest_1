require_relative '../spec_helper'

describe "/session" do
    before(:all) do
        @mysql_client = Mysql2::Client.new(
            :host => ENV['WIRED7_CORE_HOST'],
            :username => ENV['WIRED7_CORE_USERNAME'],
            :password => ENV['WIRED7_CORE_PASSWORD'],
            :database => "w7_core_#{ENV['RACK_ENV']}"
        )
        @redis = Redis.new(:host => ENV['WIRED7_REDIS_HOST'], :port => ENV['WIRED7_REDIS_PORT'], :db => ENV['WIRED7_REDIS_DB'])
    end
    before(:each) do
        access_token = "12345"
        @username = "adam123"
        @email = "adam+0@wired7.com"
        @avatar_url = "a.jpg"
        access = {
            :access_token => access_token
        }
        emails = [
            {:email => @email}
        ]
        user = {
            :avatar_url => @avatar_url
        }

        @access = JSON.parse(access.to_json, object_class: OpenStruct)
        @emails = JSON.parse(emails.to_json, object_class: OpenStruct)
        @user = JSON.parse(user.to_json, object_class: OpenStruct)
        Octokit::Client.any_instance.stub(:exchange_code_for_token) { @access }
        Octokit::Client.any_instance.stub(:emails) { @emails }
        Octokit::Client.any_instance.stub(:user) { @user }
        Octokit::Client.any_instance.stub(:login) { @username }
    end
    describe "POST" do
        context "valid auth code" do
            before(:each) do
                code = "ABCD"
                post "/session?auth_code=#{code}"
                @users = @mysql_client.query("select * from users").first
                @logins = @mysql_client.query("select * from logins").first
            end
            it "should save a new auth token in redis" do
                res = JSON.parse(last_response.body)
                expect("auth:#{res["w7_token"]}").to eq(@redis.keys("*")[0])
            end
            it "should return a 200" do
                expect(last_response.status).to eq 200
            end
            it "should return success" do
                res = JSON.parse(last_response.body)
                expect(res["success"]).to be true
            end
            context "users" do
                it "should save email" do
                    expect(@users["email"]).to eq(@email)
                end
                it "should save username" do
                    expect(@users["username"]).to eq(@username)
                end
                it "should save jwt" do
                    res = JSON.parse(last_response.body)
                    expect(@users["jwt"]).to eq(res["w7_token"])
                end
                it "should save ip" do
                    expect(@users["ip"]).to eq("127.0.0.1")
                end
                it "should save avatar" do
                    expect(@users["avatar"]).to eq(@avatar_url)
                end 
            end
            context "logins" do
                it "should save ip" do
                    expect(@logins["ip"]).to eq("127.0.0.1")
                end
                it "should save user" do
                    expect(@logins["user"]).to eq(1)
                end
            end
        end
        context "invalid auth code" do
            before(:each) do
                @access = JSON.parse({}.to_json, object_class: OpenStruct)
                Octokit::Client.any_instance.stub(:exchange_code_for_token) { @access }
                code = "ABCD"
                post "/session?auth_code=#{code}"
            end
            it "should not return success" do
                res = JSON.parse(last_response.body)
                expect(res["success"]).to be false
            end
            it "should return a 401" do
                expect(last_response.status).to eq 401
            end
            it "should not return an auth token" do
                res = JSON.parse(last_response.body)
                expect(res["w7_token"]).to be nil
            end
            it "should not save a new auth token in redis" do
                expect(@redis.keys("*").length).to eq 0
            end
        end
    end
    describe "DELETE", :focus => true do
        before(:each) do
            post "/session?auth_code=1234"
            @token = JSON.parse(last_response.body)["w7_token"]
        end 
        context "success" do
            it "should return 200" do
                delete "/session", {}, {"HTTP_AUTHORIZATION" => "Bearer #{@token}"} 
                expect(last_response.status).to eq 200
            end
        end
        context "bad token" do
            it "should return 200" do
                delete "/session", {}, {"HTTP_AUTHORIZATION" => "Bearer #{@token}"}
                expect(last_response.status).to eq 200
            end
        end
    end
end

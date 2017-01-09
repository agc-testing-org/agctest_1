require_relative '../spec_helper'

describe "API", :focus => true do
    before(:all) do
        @mysql_client = Mysql2::Client.new(
            :host => ENV['INTEGRATIONS_MYSQL_HOST'],
            :username => ENV['INTEGRATIONS_MYSQL_USERNAME'],
            :password => ENV['INTEGRATIONS_MYSQL_PASSWORD'],
            :database => "integrations_#{ENV['RACK_ENV']}"
        )
        @redis = Redis.new(:host => ENV['INTEGRATIONS_REDIS_HOST'], :port => ENV['INTEGRATIONS_REDIS_PORT'], :db => ENV['INTEGRATIONS_REDIS_DB'])
    end
    describe "POST /register" do
        shared_examples_for "register" do
            context "response" do
                it "should return code of 201" do
                    expect(last_response.status).to eq 201
                end
                it "should return success = true" do
                    expect(@res[:success]).to be true
                end
            end
            context "users" do
                it "should save email" do
                    expect(@users["email"]).to eq(@email)
                end
                it "should save name" do
                    expect(@users["name"]).to eq(@name)
                end
                it "should save ip" do
                    expect(@users["ip"]).to eq(@ip)
                end
            end
        end
        context "new user" do
            before(:each) do
                @name = "adam"
                @ip = "127.0.0.1"
                @email = "adam+01@wired7.com"
                post "/register", {:name => @name, :email=> @email}.to_json
                @res = JSON.parse(last_response.body, :symbolize_names => true)
                @users = @mysql_client.query("select * from users where email = '#{@email}'").first
                @logins = @mysql_client.query("select * from logins").first
            end
            it_behaves_like "register"
        end
        context "existing user" do
            fixtures :users
            before(:each) do
                @name = users(:adam).name
                @email = users(:adam).email
                post "/register", {:name => @name, :email=> @email}.to_json
                @res = JSON.parse(last_response.body, :symbolize_names => true)
                @users = @mysql_client.query("select * from users where email = '#{@email}'").first
                @logins = @mysql_client.query("select * from logins").first
            end
            it_behaves_like "register"
        end
    end

    context "POST /reset" do
        fixtures :users
        context "with valid password" do
            before(:each) do
                @password = 'pass1221ef31'
                #expect(Zxcvbn.test(@password).score).to eq(2)
            end
            context "with valid token" do
                context "non-protected account" do
                    before(:each) do
                        @query = "select * from users where id = #{users(:adam_confirmed).id}"
                        @token = users(:adam_confirmed).token
                        @email_hash = Digest::MD5.hexdigest(users(:adam_confirmed).email)
                        post "/reset", { :password => @password, :token => "#{@email_hash}-#{@token}" }.to_json 
                        @res = JSON.parse(last_response.body)
                    end
                    it "should return success = true" do
                        expect(@res["success"]).to eq(true)
                    end
                    it "should save new password" do 
                        expect(BCrypt::Password.new(@mysql_client.query(@query).first["password"])).to eq(@password)
                    end
                end
                context "protected account" do
                    before(:each) do
                        post "/reset", { :password => @password, :token => "#{Digest::MD5.hexdigest(users(:adam_protected).email)}-#{users(:adam_protected).token}" }.to_json 
                        @res = JSON.parse(last_response.body)
                    end
                    it "should set protected to false" do
                        expect(@mysql_client.query("select * from users where email = '#{users(:adam_protected).email}'").first["protected"]).to eq(0)
                    end
                end
            end
            context "with token older than 24 hours / invalid" do
                before(:each) do
                    @token = users(:adam).token
                    @query = "select * from users where id = #{users(:adam).id}"
                    @email_hash = Digest::MD5.hexdigest(users(:adam).email)
                    post "/reset", { :password => @password, :token => "#{@email_hash}-#{@token}" }.to_json 
                    @res = JSON.parse(last_response.body)
                end
                it "should return success = false" do
                    expect(@res["success"]).to eq(false)
                end
                it "should not save password" do
                    expect(@mysql_client.query(@query).first["password"]).to eq(users(:adam).password)
                end
            end
        end
        context "with invalid password" do
            before(:each) do
                @token = users(:adam).token
                @query = "select * from users where id = #{users(:adam).id}"
                @email_hash = Digest::MD5.hexdigest(users(:adam).email)
                @password = 123
                post "/reset", { :password => @password, :token => "#{@email_hash}-#{@token}" }.to_json
                @res = JSON.parse(last_response.body)
            end
            it "should return success = false" do
                expect(@res["success"]).to eq(false)
            end
            it "should not save password" do
                expect(@mysql_client.query(@query).first["password"]).to eq(users(:adam).password)
            end
        end
    end

    describe "POST /session/:provider" do

    end
    describe "DELETE /session" do

    end

    describe "DELETE" do
        before(:each) do


        end 
        context "success" do
            it "should return 200" do
                delete "/session", {}, {"HTTP_AUTHORIZATION" => "Bearer #{@token}"} 

            end
        end
        context "bad token" do
            it "should return 200" do
                delete "/session", {}, {"HTTP_AUTHORIZATION" => "Bearer #{@token}"}
            end
        end
    end
end

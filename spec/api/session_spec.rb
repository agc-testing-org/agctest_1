require_relative '../spec_helper'

describe "API" do
    before(:all) do
        @mysql_client = Mysql2::Client.new(
            :host => ENV['INTEGRATIONS_MYSQL_HOST'],
            :username => ENV['INTEGRATIONS_MYSQL_USERNAME'],
            :password => ENV['INTEGRATIONS_MYSQL_PASSWORD'],
            :database => "integrations_#{ENV['RACK_ENV']}"
        )
        @redis = Redis.new(:host => ENV['INTEGRATIONS_REDIS_HOST'], :port => ENV['INTEGRATIONS_REDIS_PORT'], :db => ENV['INTEGRATIONS_REDIS_DB'])
    end

    shared_examples_for "new_session" do
        it "should return success = true" do
            expect(@res["success"]).to eq(true)
        end
        it "should return w7 token" do
            expect(@mysql_client.query(@query).first["jwt"]).to eq(@res["w7_token"])
        end
        it "should save w7 token in redis" do
            expect("session:#{@res["w7_token"]}").to eq(@redis.keys("*")[0])
        end
        it "should save new password" do
            expect(BCrypt::Password.new(@mysql_client.query(@query).first["password"])).to eq(@password)
        end
    end

    describe "POST /register" do
        fixtures :roles
        before(:each) do
            @roles = [ 
                { 
                    :active => true,
                    :id => 1
                },
                {
                    :active => false,
                    :id => 2
                }
            ]
        end
        shared_examples_for "register" do
            before(:each) do
                @res = JSON.parse(last_response.body, :symbolize_names => true)
                @logins = @mysql_client.query("select * from logins").first
            end
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
                post "/register", {:name => @name, :email=> @email, :roles => @roles}.to_json
                @users = @mysql_client.query("select * from users where email = '#{@email}'").first
                @user_roles = @mysql_client.query("select * from user_roles")
            end
            it_behaves_like "register"
            context "user_roles" do
                it "should save user roles" do
                    expect(@user_roles.count).to be > 0
                    @user_roles.each_with_index do |r,i|
                        expect(r["role_id"]).to eq(@roles[i][:id])
                    end
                end
            end
        end
        context "existing user" do
            fixtures :users
            before(:each) do
                @name = users(:adam).name
                @email = users(:adam).email
                post "/register", {:name => @name, :email=> @email, :roles => @roles}.to_json
                @users = @mysql_client.query("select * from users where email = '#{@email}'").first
            end
            it_behaves_like "register" # don't want to let user know account exists, unless owner -- send email
            context "database" do
                it "does not update the record" do
                    expect(@users["created_at"].to_s(:db)).to eq(users(:adam).created_at.to_s(:db))
                end
            end
        end
    end

    context "POST /forgot" do
        context "valid email, even if not in DB" do
            before(:each) do
                post "/forgot", { :email => "a@a.co" }.to_json 
            end
            it "should return success = true" do
                expect(JSON.parse(last_response.body)["success"]).to be true
            end
        end
        context "invalid email" do
            before(:each) do 
                post "/forgot", { :email => "a@.c" }.to_json 
            end
            it "should return success = false" do
                expect(JSON.parse(last_response.body)["success"]).to be false
            end
        end
    end

    context "POST /login" do
        fixtures :users 
        context "with valid password" do
            before(:each) do
                @password = "adam12345"
                post "/login", { :password => @password, :email => users(:adam_confirmed).email }.to_json 
                @res = JSON.parse(last_response.body)
                @query = "select * from users where id = #{users(:adam_confirmed).id}"
            end
            it_behaves_like "new_session"
        end
        context "invalid" do
            after(:each) do
                res = JSON.parse(last_response.body)
                expect(res["success"]).to be false
                expect(last_response.status).to eq 200
            end
            context "email" do
                before(:each) do
                    password = "adam12345"
                    post "/login", { :password => password, :email => users(:adam).email }.to_json
                end
            end
            context "password" do
                before(:each) do
                    post "/login", { :password => "123", :email => users(:adam_confirmed).email }.to_json
                end
            end
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
                    it_behaves_like "new_session"
                end
                context "protected account" do
                    before(:each) do
                        @query = "select * from users where id = #{users(:adam_protected).id}"
                        post "/reset", { :password => @password, :token => "#{Digest::MD5.hexdigest(users(:adam_protected).email)}-#{users(:adam_protected).token}" }.to_json 
                        @res = JSON.parse(last_response.body)
                    end
                    it "should set protected to false" do
                        expect(@mysql_client.query("select * from users where email = '#{users(:adam_protected).email}'").first["protected"]).to eq(0)
                    end
                    it_behaves_like "new_session"
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

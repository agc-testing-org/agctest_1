require 'spec_helper'

describe "API" do
    shared_examples_for "session_response" do
        it "should return success = true" do
            expect(@res["success"]).to eq(true)
        end
        it "should return w7 token" do
            expect(@mysql_client.query(@query).first["jwt"]).to eq(@res["w7_token"])
        end
    end
    shared_examples_for "new_session" do
        it "should save w7 token in redis" do
            expect("session:#{@res["w7_token"]}").to eq(@redis.keys("*")[0])
        end
        it "should save user id in redis" do
             expect(JSON.parse(@redis.get("session:#{@res["w7_token"]}"))["id"]).to eq(@mysql_client.query(@query).first["id"])
        end
        it "should save user admin status in redis" do
            expect(JSON.parse(@redis.get("session:#{@res["w7_token"]}"))["admin"]).to eq(!@mysql_client.query(@query).first["admin"].zero?)
        end
        it "should save user first name in redis" do
            expect(JSON.parse(@redis.get("session:#{@res["w7_token"]}"))["first_name"]).to eq(@mysql_client.query(@query).first["first_name"])
        end
        it "should save user last name in redis" do
            expect(JSON.parse(@redis.get("session:#{@res["w7_token"]}"))["last_name"]).to eq(@mysql_client.query(@query).first["last_name"])
        end
        it "should save github_username in redis" do
            expect(JSON.parse(@redis.get("session:#{@res["w7_token"]}"))["github_username"]).to eq(@mysql_client.query(@query).first["github_username"])
        end
        if @password
            it "should save new password" do
                expect(BCrypt::Password.new(@mysql_client.query(@query).first["password"])).to eq(@password)
            end
        end
    end

    describe "POST /register" do
        fixtures :roles
        before(:each) do
            @roles = [ 
                { 
                    :active => true,
                    :id => roles(:product).id
                },
                {
                    :active => false,
                    :id => roles(:quality).id
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
                it "should save first name" do
                    expect(@users["first_name"]).to eq(@first_name)
                end
                it "should save last name" do
                    expect(@users["last_name"]).to eq(@last_name)
                end
                it "should save ip" do
                    expect(@users["ip"]).to eq(@ip)
                end
            end
        end
        context "new user" do
            before(:each) do
                @first_name = "adam"
                @last_name = "cockell"
                @ip = "127.0.0.1"
                @email = "adam+01@wired7.com"
                post "/register", {:first_name => @first_name, :last_name => @last_name, :email=> @email, :roles => @roles}.to_json
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
                @first_name = users(:adam).first_name
                @email = users(:adam).email
                post "/register", {:first_name => @first_name, :email=> @email, :roles => @roles}.to_json
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
                @email = users(:adam_confirmed).email
                post "/login", { :password => @password, :email => @email }.to_json 
                @res = JSON.parse(last_response.body)
                @query = "select * from users where id = #{users(:adam_confirmed).id}"
            end
            it_behaves_like "session_response"
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

    context "GET /account" do
        fixtures :users
        context "signed in" do
            before(:each) do
                @password = "adam12345"
                @email = users(:adam_confirmed).email
                post "/login", { :password => @password, :email => @email }.to_json
                res = JSON.parse(last_response.body)
                w7_token = res["w7_token"]
                get "/account",{},{"HTTP_AUTHORIZATION" => "Bearer #{w7_token}"}
                @res = JSON.parse(last_response.body)
            end
            it "should include user id" do
                expect(@res["id"]).to eq(users(:adam_confirmed).id)
            end
            it "should include user admin" do
                expect(@res["admin"]).to eq(users(:adam_confirmed).admin)
            end
            it "should include github signed in status" do
                expect(@res.keys).to include("github")
            end
            it "should include github_username" do
                expect(@res.keys).to include("github_username")
            end
            it "should include user name" do
                expect(@res["first_name"]).to eq(users(:adam_confirmed).first_name)
            end
            it "should not return key" do
                expect(@res["key"]).to be nil
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
                        @email = users(:adam_confirmed).email
                        @email_hash = Digest::MD5.hexdigest(users(:adam_confirmed).email)
                        post "/reset", { :password => @password, :token => "#{@email_hash}-#{@token}" }.to_json 
                        @res = JSON.parse(last_response.body)
                        @query = "select * from users where id = #{users(:adam_confirmed).id}"
                    end
                    it_behaves_like "session_response"
                    it_behaves_like "new_session"
                end
                context "protected account" do
                    before(:each) do
                        @query = "select * from users where id = #{users(:adam_protected).id}"
                        @email = users(:adam_protected).email
                        post "/reset", { :password => @password, :token => "#{Digest::MD5.hexdigest(users(:adam_protected).email)}-#{users(:adam_protected).token}" }.to_json 
                        @res = JSON.parse(last_response.body)
                        @query = "select * from users where id = #{users(:adam_protected).id}"
                    end
                    it "should set protected to false" do
                        expect(@mysql_client.query("select * from users where email = '#{users(:adam_protected).email}'").first["protected"]).to eq(0)
                    end
                    it_behaves_like "session_response"
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
            context "invitation" do
                fixtures :teams, :user_teams
                context "valid token" do
                    before(:each) do
                        @token = user_teams(:adam_confirmed_b_team).token
                        post "/reset", { :password => @password, :token => @token, :invitation => true }.to_json
                        @res = JSON.parse(last_response.body)
                        @query = "select * from users where id = #{users(:adam_confirmed).id}"
                        @user_teams_result = @mysql_client.query("select * from user_teams where team_id = #{user_teams(:adam_confirmed_b_team).team_id}")
                    end
                    it_behaves_like "session_response"
                    it_behaves_like "new_session"
                    it "should set accepted = true" do
                        expect(@user_teams_result.first["accepted"]).to be 1
                    end
                end
                context "expired token" do
                    before(:each) do
                        post "/reset", { :password => @password, :token => "ZRY", :invitation => true }.to_json
                        @res = JSON.parse(last_response.body)
                        @query = "select * from users where id = #{users(:adam_confirmed).id}"
                    end
                    it "should return success = false" do
                         expect(@res["success"]).to eq(false)
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
    end

    describe "POST /session/github" do
        fixtures :users
        before(:each) do
            @password = "adam12345"
            @email = users(:adam_confirmed).email
            post "/login", { :password => @password, :email => @email }.to_json
            res = JSON.parse(last_response.body)
            @w7_token = res["w7_token"]
            @username = "adam_on_github"
        end
        context "github" do
            before(:each) do
                @code = "123"
                @access_token = "ACCESS123"

                Octokit::Client.any_instance.stub(:exchange_code_for_token) { JSON.parse({
                    :access_token => @access_token
                }.to_json, object_class: OpenStruct) }
                Octokit::Client.any_instance.stub(:login) { @username }

                post "/session/github", {:grant_type => "github", :auth_code => @code }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@w7_token}"}
                @res = JSON.parse(last_response.body)
                @query = "select * from users where id = #{users(:adam_confirmed).id}"
            end
            it_behaves_like "session_response"
            it_behaves_like "new_session"
            it "should return github token" do
                account = Account.new
                token = account.validate_token @res["github_token"], JSON.parse(@redis.get("session:#{@res["w7_token"]}"))["key"]
                expect(token["payload"]).to eq(@access_token)
            end
            context "users table" do
                it "should save github_username" do
                    expect(@mysql_client.query("select * from users").first["github_username"]).to eq(@username)
                end
            end
        end
    end

    describe "POST /session/linkedin" do
        fixtures :users
        before(:each) do
            @password = "adam12345"
            @email = users(:adam_confirmed).email
            post "/login", { :password => @password, :email => @email }.to_json
            res = JSON.parse(last_response.body)
            @w7_token = res["w7_token"]
        end
        context "linkedin" do
            before(:each) do
                access_token = "ABC"
                code = "123"
                @headline = "headline"
                @location = {:country => {:code => "US"}, :name => "San Francisco Bay"}
                @summary = "summary"
                @positions = {:all => [{:title => "Engineer", :company => {:name => "COMPANY", :size => "120-500", :industry => "Software"}, :start_date => {:year => 2000}, :end_date => {:year => 2006}}]}
                LinkedIn::OAuth2.any_instance.stub(:get_access_token) { JSON.parse({
                    :token => access_token
                }.to_json, object_class: OpenStruct) }
                LinkedIn::API.any_instance.stub(:profile) { JSON.parse({
                    :headline => @headline,
                    :location => @location,
                    :summary => @summary,
                    :positions => @positions
                }.to_json, object_class: OpenStruct) }
                post "/session/linkedin", {:auth_code => code }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@w7_token}"}
                @res = JSON.parse(last_response.body)
                @query = "select * from users where id = #{users(:adam_confirmed).id}"
            end
            it_behaves_like "session_response"
            context "user_profile" do
                before(:each) do
                    @user_profiles = @mysql_client.query("select * from user_profiles").first
                end
                context "user_profiles" do
                    it "should include user_id" do
                        expect(@user_profiles["user_id"]).to eq users(:adam_confirmed).id
                    end
                    it "should include headline" do
                        expect(@user_profiles["headline"]).to eq @headline
                    end
                    it "should include location_country_code" do
                        expect(@user_profiles["location_country_code"]).to eq @location[:country][:code]
                    end
                    it "should include location_name" do
                        expect(@user_profiles["location_name"]).to eq @location[:name]
                    end
                end
            end
            context "user_position" do
                before(:each) do
                    @user_positions = @mysql_client.query("select * from user_positions").first
                end
                it "should include user_profile_id" do
                    expect(@user_positions["user_profile_id"]).to eq(1)
                end
                it "should include title" do
                    expect(@user_positions["title"]).to eq @positions[:all][0][:title]
                end
                it "should include size" do
                    expect(@user_positions["size"]).to eq @positions[:all][0][:company][:size]
                end
                it "should include start_year" do
                    expect(@user_positions["start_year"]).to eq @positions[:all][0][:start_date][:year]
                end
                it "should include end_year" do
                    expect(@user_positions["end_year"]).to eq @positions[:all][0][:end_date][:year]
                end
                it "should include company" do
                    expect(@user_positions["company"]).to eq @positions[:all][0][:company][:name]
                end
                it "should include industry" do
                    expect(@user_positions["industry"]).to eq @positions[:all][0][:company][:industry]
                end
            end
        end
    end

    describe "DELETE /session" do
        fixtures :users
        before(:each) do
            @password = "adam12345"
            @email = users(:adam_confirmed).email
            post "/login", { :password => @password, :email => @email }.to_json
            res = JSON.parse(last_response.body)
            @w7_token = res["w7_token"]

            delete "/session", {}, {"HTTP_AUTHORIZATION" => "Bearer #{@w7_token}"}
        end
        it "should delete session from redis" do
            expect(@redis.exists("session:#{@w7_token}")).to be false
        end
        it "should return 200" do
            expect(last_response.status).to eq 200
        end
    end
end

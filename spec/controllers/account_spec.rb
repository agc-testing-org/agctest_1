require_relative '../spec_helper'

describe ".Account" do
    before(:each) do
        @account = Account.new
    end   
    context "#linkedin_code_for_token" do
        before(:each) do
            @code = "123"
            @access_token = "ACCESS123"
        end
        context "service error" do
            before(:each) do
                LinkedIn::OAuth2.any_instance.stub(:get_access_token) { JSON.parse({
                    :error => true
                }.to_json, object_class: OpenStruct) }
                @res = @account.linkedin_code_for_token @code
            end
            it "should return nil" do
                expect(@res).to be nil
            end
        end
        context "service success" do
            before(:each) do
                LinkedIn::OAuth2.any_instance.stub(:get_access_token) { JSON.parse({
                    :token => @access_token
                }.to_json, object_class: OpenStruct) }
                @res = @account.linkedin_code_for_token @code
            end
            it "should return access_token" do
                expect(@res).to eq(@access_token)
            end
        end
    end
    context "linkedin_profile" do
        before(:each) do 
            @headline = "headline"
            @location = {:country => {:code => "US"}, :name => "San Francisco Bay"}
            @summary = "summary"
            LinkedIn::API.any_instance.stub(:profile) { JSON.parse({
                :headline => @headline,
                :location => @location,
                :summary => @summary,
                :positions => @positions
            }.to_json, object_class: OpenStruct) }
            client = LinkedIn::API.new("123")
            @pull = @account.pull_linkedin_profile client
        end
        context "#pull_linkedin_profile" do
            it "should return headline" do
                expect(@pull.headline).to eq @headline
            end
            it "should return location.country.code" do
                expect(@pull.location.country.code).to eq @location[:country][:code]
            end
            it "should return location.name" do
                expect(@pull.location.name).to eq @location[:name]
            end
            it "should return summary" do
                expect(@pull.summary).to eq @summary
            end
            it "should return positions" do
                expect(@pull.positions).to eq @positions
            end
        end
    end
    context "#github_code_for_token" do
        before(:each) do
            @code = "123"
            @access_token = "ACCESS123"
        end
        context "service error" do
            before(:each) do
                Octokit::Client.any_instance.stub(:exchange_code_for_token) { JSON.parse({      
                    :error => true 
                }.to_json, object_class: OpenStruct) }
                @res = @account.github_code_for_token @code
            end
            it "should return nil" do
                expect(@res).to be nil
            end
        end
        context "service success" do
            before(:each) do
                Octokit::Client.any_instance.stub(:exchange_code_for_token) { JSON.parse({ 
                    :access_token => @access_token
                }.to_json, object_class: OpenStruct) }
                @res = @account.github_code_for_token @code
            end
            it "should return access_token" do
                expect(@res).to eq(@access_token)
            end
        end
    end

    context "#redis_connection" do
        it "should return a redis connection" do
            expect(@account.redis_connection.inspect).to include("redis:")
        end
    end

    context "#create_client_and_secret" do
        before(:all) do
            @secret = "ABC"
        end
        it "should return md5 of client and user secrets" do
            expect(@account.create_client_and_secret @secret).to eq(Digest::MD5.hexdigest("#{ENV['WIRED7_HMAC']}:#{@secret}"))
        end
    end
    context "#create_jti" do
        before(:all) do
            @iat = 1000
            @md5 = "MD5HASH"
        end
        it "should return md5 of md5(client + user secrets) and iat, issue time" do
            expect(@account.create_jti @md5, @iat).to eq(Digest::MD5.hexdigest("#{@md5}:#{@iat}"))
        end
    end
    context "#save_token" do
        before(:each) do
            @type = "auth"
            @token = "1234567890"
            @value = "VALUE"
            @expiration = 10
            @res = @account.save_token @type, @token, @value, @expiration
        end
        it "should return true" do
            expect(@res).to be true
        end
        context "redis" do
            it "should save the token as a key with '#{@type}:'" do
                expect(@redis.exists("#{@type}:#{@token}")).to be true 
            end
            it "should save the value" do
                expect(@redis.get("#{@type}:#{@token}")).to eq(@value)
            end
            it "should add a TTL of #{@expiration} seconds to the token" do
                expect(@redis.ttl("#{@type}:#{@token}")).to eq(@expiration)
            end
        end
    end
    context "#create_token" do
        before(:each) do
            @id = 1
            @secret = "SECRET"
            @payload = {"github" => "GHB"}
            @token = @account.create_token @id, @secret, @payload
            @res, @header = JWT.decode @token, Digest::MD5.hexdigest("#{ENV['INTEGRATIONS_HMAC']}:#{@secret}"), true, { :verify_iat => true, :verify_jti => true, :algorithm => 'HS256' }
        end
        context "context jwt" do
            it "should contain payload" do
                expect(@res["payload"]).to eq(@payload)
            end
        end
    end
    context "#get_key" do
        before(:each) do
            @token = "123456"
            @value = "ABCDEF"
            @type = "auth"
        end
        context "key exists" do
            before(:each) do
                @redis.set("#{@type}:#{@token}", @value)
            end
            it "should return value" do
                expect(@account.get_key @type, @token).to eq(@value)
            end
        end
        context "key does not exist" do
            it "should return nil" do
                expect(@account.get_key @type, @token).to be nil
            end
        end
    end
    context "#validate_token" do
        before(:each) do
            @id = 1
            @secret = "SECRET"
            @load = {"github" => "GHB"}
        end
        context "valid token" do
            before(:each) do
                @valid_token = @account.create_token @id, @secret, @load
                @payload = @account.validate_token @valid_token, @secret
            end
            context "payload" do
                it "should return payload" do
                    expect(@payload["payload"]).to eq(@load)
                end
                it "should return iat" do
                    expect(@payload["iat"]).to be <= Time.now.to_i
                end
                it "should return jti" do
                    expect(@payload["jti"]).to eq(Digest::MD5.hexdigest("#{Digest::MD5.hexdigest("#{ENV['INTEGRATIONS_HMAC']}:#{@secret}")}:#{@payload["iat"]}"))
                end
            end
        end
        context "invalid token" do
            context "invalid jti" do
                it "should return nil" do
                    payload = {
                        :iat => Time.now.to_i,
                        :jti => "1234",
                        :user_id => 1,
                        :payload =>  {"github" => "GHB"} 
                    }
                    token = JWT.encode payload, Digest::MD5.hexdigest("#{ENV['INTEGRATIONS_HMAC']}:#{@secret}"), "HS256"
                    expect(@account.validate_token token, @secret).to be nil
                end
            end
            context "invalid secret" do
                it "should return nil" do
                    payload = {
                        :iat => Time.now.to_i,
                        :jti => Digest::MD5.hexdigest("#{Digest::MD5.hexdigest("#{ENV['INTEGRATIONS_HMAC']}:#{@secret}")}:#{Time.now.to_i}"),
                        :user_id => 1,
                            :payload =>  {"github" => "GHB"}                  
                    }
                    token = JWT.encode payload, Digest::MD5.hexdigest("#{ENV['INTEGRATIONS_HMAC']}:#{@secret}"), "HS256"
                    expect(@account.validate_token token, "ABC").to be nil
                end
            end
        end
    end

    context "#unlock_github_token" do
        before(:each) do
            @id = 1
            @key = "KEY"
            @access_token = "123456"
            @session = "ABC"
            @provider_token = @account.create_token @id, @key, @access_token
            @expiration = 10
            @account.save_token "session", @session, {:key => @key}.to_json, @expiration

        end
        context "valid token" do
            it "should return access_token" do
                expect(@account.unlock_github_token @session, @provider_token).to eq(@access_token)
            end
        end
    end

    context "#delete_token" do
        before(:each) do
            @type = "auth"
            @token = "123456"
            @secret = "ABCDEF"
        end
        context "exists" do
            before(:each) do
                @redis.set("#{@type}:#{@token}", @secret)
                @res = @account.delete_token @type, @token 
            end
            it "should return OK" do
                expect(@res).to be true
            end
            it "should delete the token" do
                expect(@redis.exists("auth:#{@token}")).to be false
            end
        end
        context "does not exist" do
            it "should return false" do
                expect(@account.delete_token @type, @token).to be false
            end
        end
    end

    context "#create" do
        context "email does exist" do
            fixtures :users
            before(:each) do
                ip = "192.168.1.1"
                @res = @account.create users(:adam).email, users(:adam).first_name, users(:adam).last_name, ip 
            end
            it "should return nil id" do
                expect(@res["id"]).to be nil 
            end
            it "should not create a new record in the users table" do
                expect(@mysql_client.query("select * from users where email = '#{users(:adam).email}'").count).to eq(1)
            end
        end
        context "email does not exist" do
            before(:each) do
                @email = "Adam0@wired7.com"
                @first_name = "ADAM"
                @last_name = "COCKELL"
                @ip = "192.168.1.1"
                @res = @account.create @email, @first_name, @last_name, @ip
                @mysql = @mysql_client.query("select * from users").first
            end
            it "should return user object" do
                expect(@res.token).to eq(@mysql["token"])
            end
            context "users table" do
                it "should include downcased email" do
                    expect(@mysql["email"]).to eq(@email.downcase)
                end
                it "should include first name" do
                    expect(@mysql["first_name"]).to eq(@first_name)
                end
                it "should include last name" do
                    expect(@mysql["last_name"]).to eq(@last_name)
                end
                it "should include admin = 0" do
                    expect(@mysql["admin"]).to eq(0)
                end
                it "should include protected = false" do
                    expect(@mysql["protected"]).to be 0
                end
                it "should include ip" do
                    expect(@mysql["ip"]).to eq @ip
                end
            end
        end
    end
    context "#update" do
        fixtures :users
        before(:each) do
            @ip = "192.168.1.1"
            @jwt = "1234567890"
            update_fields = {
                :ip => @ip,
                :jwt => @jwt
            }
            @res = @account.update users(:adam).id, update_fields 
            @record = @mysql_client.query("select * from users where id = #{users(:adam).id}").first
        end
        context "response" do
            it "should return boolean for success" do
                expect(@res).to be true
            end
        end
        context "users table" do
            it "should save ip address" do
                expect(@record["ip"]).to eq(@ip)
            end
            it "should save jwt" do
                expect(@record["jwt"]).to eq(@jwt)
            end
        end
    end
    context "#get" do
        context "account exists" do
            fixtures :users
            before(:each) do
                params = {:id => users(:adam).id}
                @res = @account.get params
            end
            context "object" do
                it "should include email" do
                    expect(@res.email).to eq(users(:adam).email)
                end
                it "should include include protected" do
                    expect(@res.protected).to be false
                end
                it "should include lock" do
                    expect(@res.lock).to be false
                end
            end
        end
        context "account does not exist" do
            before(:each) do
                params = {:id => 2}
                @res = @account.get params
            end
            it "should return nil" do
                expect(@res).to be nil
            end
        end
    end
    context "#record_login" do
        context "no users foreign key" do
            before(:each) do
                @res = @account.record_login 22, "123.56"
            end
            it "should return nil" do
                expect(@res).to be nil
            end
        end
        context "users foreign key exists" do
            fixtures :users
            before(:each) do
                @ip = "192.168.1.1"
                @id = users(:adam).id
                @provider = 1
                @res = @account.record_login @id, @ip
                @record = @mysql_client.query("select * from logins where user_id = #{users(:adam).id}").first
            end
            context "response" do
                it "should return id of login" do
                    expect(@res).to eq 1
                end
            end
            context "logins table" do
                it "should save user id" do
                    expect(@record["user_id"]).to eq(@id)
                end
                it "should save ip address" do
                    expect(@record["ip"]).to eq(@ip)
                end
            end
        end
    end
    context "#safe_string" do
        context "length" do
            before(:each) do
                @string = "123"
            end
            it "should return false if string length is less than length" do
                expect(@account.safe_string @string, 4).to be false
            end
            it "should return true if string length is equal to length" do
                expect(@account.safe_string @string, 3).to be true
            end
            it "should return true if string length is greater than length" do
                expect(@account.safe_string @string, 2).to be true
            end
        end
        context "characters" do
            before(:each) do
                @length = 3
            end
            it "should allow letters" do
                expect(@account.safe_string "ABCD", @length).to be true
            end
            it "should allow numbers" do
                expect(@account.safe_string "1234", @length).to be true
            end
            it "should allow dash" do
                expect(@account.safe_string "ABC-", @length).to be true
            end
            it "should not allow underscore" do
                expect(@account.safe_string "ABC_", @length).to be false 
            end
            it "should not allow comma" do
                expect(@account.safe_string "ABC,", @length).to be false 
            end
            it "should not allow period" do
                expect(@account.safe_string "ABC.", @length).to be false 
            end
            it "should not allow apostrophe" do
                expect(@account.safe_string "ABC'", @length).to be false
            end
        end
    end
    context "#valid_email" do
        context "valid" do
            ["a@w.com","a@w.ly"].each do |email|
                it "should return true" do
                    expect(@account.valid_email email).to be true
                end
            end
        end
        context "invalid" do
            ["a@.com","@w.ly","123","@","ABCD"].each do |email|
                it "should return false" do
                    expect(@account.valid_email email).to be false
                end
            end
        end
    end

    context "#request_token" do
        context "when an account exists" do
            fixtures :users
            before(:each) do
                @email = users(:adam).email
                @res = @account.request_token @email
                @upload_query = "select * from users where id = #{users(:adam).id}"
            end
            it "should return true" do
                expect(@res).to eq(true)
            end
            it "should save a token to the database" do
                expect(@mysql_client.query(@upload_query).first["token"]).to_not be_empty
            end
            it "should save a random token" do
                first_token = users(:adam).token
                second_token = @mysql_client.query(@upload_query).first["token"]
                expect(first_token).to_not eq(second_token)
            end
        end
        context "when an account does not exist" do
            it "should return false" do
                expect(@account.request_token "adam12345@wired7.com").to eq(false)
            end
        end
    end

    context "#get_reset_token" do
        context "when an account exists" do
            fixtures :users
            before(:each) do
                @email = users(:adam).email
                @email_hash = Digest::MD5.hexdigest(@email)
                @query = "select * from users where id = #{users(:adam).id}"
            end
            context "token generated 24 hours +" do
                before(:each) do
                    @res = @account.get_reset_token "#{@email_hash}-#{users(:adam).token}"
                end
                it "should return nil" do
                    expect(@res).to be nil 
                end
                it "should not update confirmed" do
                    expect(@mysql_client.query(@query).first["confirmed"]).to eq(0)
                end
                it "should not save the new password" do
                    expect(@mysql_client.query(@query).first["password"]).to eq(users(:adam).password)
                end
            end
            context "token generated within 24 hours" do
                before(:each) do
                    @account.request_token @email
                    @res = @account.get_reset_token "#{@email_hash}-#{@mysql_client.query(@query).first["token"]}"
                end
                it "should return user object" do
                    expect(@res[:id]).to eq(@mysql_client.query(@query).first["id"])
                end

            end
        end
        context "when an account does not exist" do
            before(:each) do
                @password = "12345678"
                @res = @account.get_reset_token "1234567865432-12121212"
            end
            it "should return false" do
                expect(@res).to be nil 
            end
        end
    end

    context "#confirm_user" do 
        fixtures :users
        before(:each) do
            @ip = '192.168.1.1'
            @password = "1235678"
            @first = "ADAM1"
            @email = users(:adam).email
            @email_hash = Digest::MD5.hexdigest(@email)
            @account.request_token @email
            @query = "select * from users where id = #{users(:adam).id}"
            @token = @mysql_client.query(@query).first["token"]
        end
        context "with user object" do
            before(:each) do
                res = @account.get_reset_token "#{@email_hash}-#{@token}"
                @res = @account.confirm_user res, @password, @first, @ip
            end

            it "should save the new password" do 
                expect(BCrypt::Password.new(@mysql_client.query(@query).first["password"])).to eq(@password)
            end                                             
            it "should make the token nil" do
                expect(@mysql_client.query(@query).first["token"]).to be nil
            end                                                             
            it "should update confirmed to true" do 
                expect(@mysql_client.query(@query).first["confirmed"]).to eq(1)
            end                                                                             
            it "should save the user's ip address" do               
                expect(@mysql_client.query(@query).first["ip"]).to eq(@ip)                  
            end                                                                                             
        end
        context "protected account" do
            before(:each) do
                query = "update users SET `protected` = 1 where id = #{@token}"
                res = @account.get_reset_token "#{@email_hash}-#{users(:adam).token}"
                @res = @account.confirm_user res, @password, @first, @ip
            end
            it "should set protected to false" do
                expect(@mysql_client.query(@query).first["protected"]).to eq(0)
            end
        end
    end

    context "#get_roles" do
        fixtures :roles
        before(:each) do
            @roles = @account.get_roles
        end
        it "should return more than one result" do
            expect(@roles.length).to be > 0
        end
        it "should return name" do
            @roles.each_with_index do |r,i|
                expect(r["name"]).to eq(roles(r["name"]).name)
            end
        end
        it "should return fa_icon" do
            @roles.each_with_index do |r,i|
                expect(r["fa_icon"]).to eq(roles(r["name"]).fa_icon)
            end
        end
    end
    context "#update_role" do
        fixtures :users, :roles
        before(:each) do
            @user_id = users(:adam).id
            @role_id = roles(:product).id
            @active = true
            @account.update_role @user_id, @role_id, @active
        end
        context "user role does not exist" do
            it "should save a role" do
                @account.update_role @user_id, @role_id, @active
                query = @mysql_client.query("select * from user_roles").first
                expect(query["user_id"]).to eq(@user_id)
                expect(query["role_id"]).to eq(@role_id)
                expect(query["active"]).to eq(1)
            end
        end
        context "user role exists" do
            it "should update a role" do
                @account.update_role @user_id, @role_id, @active
                @account.update_role @user_id, @role_id, false
                query = @mysql_client.query("select * from user_roles").first
                expect(query["user_id"]).to eq(@user_id)
                expect(query["role_id"]).to eq(@role_id)
                expect(query["active"]).to eq(0)
            end
        end
        context "multiple user roles" do
            it "should add the 2nd role" do
                @account.update_role @user_id, @role_id, @active
                @account.update_role @user_id, roles(:development).id, @active
                query = @mysql_client.query("select * from user_roles")
                expect(query.count).to eq(2)
            end
        end
    end

    context "#sign_in" do
        context "when account exists" do
            fixtures :users
            context "when password is correct" do
                before(:each) do
                    @ip = '192.168.1.1'
                    @password = "adam12345"
                end
                context "when not confirmed" do
                    it "should return nil" do
                        @email = users(:adam).email
                        expect(@account.sign_in @email, @password, @ip).to be nil 
                    end
                end
                context "when confirmed" do
                    it "should return user object" do
                        @email = users(:adam_confirmed).email
                        expect((@account.sign_in @email, @password, @ip)[:id]).to eq(users(:adam_confirmed).id)                    
                    end
                end
            end
            context "when protected" do
                fixtures :users
                it "should return nil" do
                    ip = '192.168.1.1'
                    expect(@account.sign_in users(:adam_protected).email, @password, ip).to be nil 
                end
            end
            context "when password is not correct" do
                it "should return -1" do
                    expect(@account.sign_in users(:adam).email, 123, @ip).to be nil 
                end
            end
        end
        context "when account does not exist" do
            it "should return nil" do
                expect(@account.sign_in "adamm@wired7.com", @password, @ip).to be nil 
            end
        end 
    end

    context "#get_seat" do
        fixtures :users, :teams, :user_teams, :seats
        before(:each) do
            @team_id = user_teams(:adam_confirmed).team.id
        end
        context "is a member" do
            before(:each) do
                @user_id = user_teams(:adam_confirmed).user_id
                @res = @account.get_seat @user_id, @team_id
            end
            it "should return owner" do
                expect(@res).to eq(user_teams(:adam_confirmed).seat.name)
            end
        end
        context "has not accepted" do
            before(:each) do
                @user_id = user_teams(:adam_invited_expired).user_id
                @res = @account.get_seat @user_id, @team_id
            end
            it "should return false" do
                expect(@res).to be nil
            end
        end
    end

    context "#is_owner" do
        fixtures :users, :teams, :user_teams, :seats
        context "is owner on any team" do
            before(:each) do
                @user_id = user_teams(:adam_confirmed).user_id
                @res = @account.is_owner? @user_id
            end
            it "should return true" do
                expect(@res).to eq(true)
            end
        end
        context "not an owner" do
            before(:each) do
                @user_id = user_teams(:adam_invited_expired).user_id
                @mysql_client.query("update user_teams set accepted = true where id = #{user_teams(:adam_invited_expired).id}")
                @res = @account.is_owner? @user_id
            end
            it "should return false" do
                expect(@res).to be false 
            end
        end

    end

    context "#get_user_connections" do
        fixtures :users
        context "connections" do
            fixtures :user_connections
            before(:each) do
                user_id = users(:masha_get_connection_request).id
                query = {"user_connections.contact_id" => user_id}
                @res = (@account.get_user_connections query).first
            end
            it "should include user_id" do
                expect(@res["user_id"]).to eq(users(:masha_post_connection_request).id)
            end
            it "should include contact_id" do
                expect(@res["contact_id"]).to eq(users(:masha_get_connection_request).id)
            end
            it "should include read" do
                expect(@res["read"]).to eq(user_connections(:user_2_connection_1).read)
            end
            it "should include confirmed" do
                expect(@res["confirmed"]).to eq(user_connections(:user_2_connection_1).confirmed)
            end
            it "should include user_name" do
                expect(@res["first_name"]).to eq(users(:masha_get_connection_request).first_name)
            end
            it "should include created_at" do
                expect(@res["created_at"]).to_not be nil
            end
            it "should include updated_at" do
                expect(@res["updated_at"]).to_not be nil
            end
        end
    end 

    context "#get_user_connections_accepted" do
        fixtures :users
        context "user_info" do
            fixtures :user_connections
            before(:each) do
                user_id = users(:masha_post_connection_request).id
                @res = (@account.get_user_connections_accepted user_id).first
            end
            it "should include user_id" do
                expect(@res["first_name"]).to eq(users(:masha_get_connection_request).first_name)
            end
            it "should include contact_id" do
                expect(@res["email"]).to eq(users(:masha_get_connection_request).email)
            end
        end
    end 

    context "#update_user_connections" do
        fixtures :users
        context "connection_request_read" do
            fixtures :user_connections
            before(:each) do
                contact_id = (users(:masha_get_connection_request).id)
                user_id = (users(:masha_post_connection_request).id)
                @read = false
                @confirmed = 3
                @res = (@account.update_user_connections contact_id, user_id, @read, @confirmed)
            end
            it "should include read" do
                expect(@res["read"]).to eq(@read)
            end
        end
    end 

    context "#create_connection_request" do
        fixtures :users
        context "connection_request_confirmed" do
            fixtures :user_connections
            before(:each) do
                @contact_id = (users(:adam_protected).id)
                @user_id = (users(:adam).id)
                @res = (@account.create_connection_request @user_id, @contact_id)
            end
            it "should include user_id" do
                expect(@res["user_id"]).to eq(@user_id)
            end
            it "should include contact_id" do
                expect(@res["contact_id"]).to eq(@contact_id)
            end
            it "should include read" do
                expect(@res["read"]).to eq(false)
            end
            it "should include confirmed" do
                expect(@res["confirmed"]).to eq(1)
            end
        end
    end 

end

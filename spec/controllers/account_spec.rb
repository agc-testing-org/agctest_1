require_relative '../spec_helper'

describe ".Account" do
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
        @account = Account.new
    end   
    context "#code_for_token" do
        before(:each) do
            @code = "123"
            @access_token = "ACCESS123"
        end
        context "service error" do
            before(:each) do
                Octokit::Client.any_instance.stub(:exchange_code_for_token) { JSON.parse({      
                    :error => true 
                }.to_json, object_class: OpenStruct) }
                @res = @account.code_for_token @code

                @account.code_for_token @code
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
                @res = @account.code_for_token @code
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
            @res = @account.save_token @type, @token, @value
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
            it "should add a TTL of 3 hours to the token" do
                expect(@redis.ttl("#{@type}:#{@token}")).to eq(60*60*3)
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
            it "should contain user_id" do
                expect(@res["user_id"]).to eq(@id)
            end
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
                it "should return user_id" do
                    expect(@payload["user_id"]).to eq(@id)
                end
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
                @res = @account.create users(:adam).email, users(:adam).name, ip 
            end
            it "should return nil" do
                expect(@res).to eq(nil)
            end
            it "should not create a new record in the users table" do
                expect(@mysql_client.query("select * from users where email = '#{users(:adam).email}'").count).to eq(1)
            end
        end
        context "email does not exist" do
            before(:each) do
                @email = "Adam0@wired7.com"
                @name = "ADAM"
                @ip = "192.168.1.1"
                @res = @account.create @email, @name, @ip
                @mysql = @mysql_client.query("select * from users").first
            end
            it "should return token" do
                expect(@res).to eq(@mysql["token"])
            end
            context "users table" do
                it "should include downcased email" do
                    expect(@mysql["email"]).to eq(@email.downcase)
                end
                it "should include downcased name" do
                    expect(@mysql["name"]).to eq(@name.downcase)
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
                it "should include token" do
                    expect(@mysql["token"]).to_not be nil 
                end
            end
        end
    end
    context "#update" do
        fixtures :users
        before(:each) do
            @ip = "192.168.1.1"
            @jwt = "1234567890"
            @res = @account.update users(:adam).id, @ip, @jwt
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
                @res = @account.get users(:adam).id
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
                @res = @account.get 2
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

    context "#validate_reset_token" do
        before(:each) do
            @ip = '192.168.1.1'
        end
        context "when an account exists" do
            fixtures :users
            before(:each) do
                @email = users(:adam).email
                @email_hash = Digest::MD5.hexdigest(@email)
                @query = "select * from users where id = #{users(:adam).id}"
                @password = "12345678"
            end
            context "token generated 24 hours +" do
                before(:each) do
                    @res = @account.validate_reset_token "#{@email_hash}-#{users(:adam).token}", @password, @ip
                end
                it "should return false" do
                    expect(@res).to eq(false)
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
                    @res = @account.validate_reset_token "#{@email_hash}-#{@mysql_client.query(@query).first["token"]}", @password, @ip
                end
                it "should return user id" do
                    expect(@res).to eq(@mysql_client.query(@query).first["id"])
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
                    query = "update users SET `protected` = 1 where id = #{users(:adam).id}"
                    @mysql_client.query(query)
                    @account.request_token @email
                    @res = @account.validate_reset_token "#{@email_hash}-#{@mysql_client.query(@query).first["token"]}", @password, @ip
                end
                it "should set protected to false" do
                    expect(@mysql_client.query(@query).first["protected"]).to eq(0)
                end
            end
        end
        context "when an account does not exist" do
            before(:each) do
                @password = "12345678"
                @res = @account.validate_reset_token "1234567865432-12121212", @password, @ip
            end
            it "should return false" do
                expect(@res).to eq(false)
            end
        end
    end
end

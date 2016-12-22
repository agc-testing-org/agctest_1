require_relative '../spec_helper'

describe ".Account" do
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
        @account = Account.new
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
            @token = "1234567890"
            @secret = "SECRET"
            @res = @account.save_token @token, @secret
        end
        it "should return true" do
            expect(@res).to be true
        end
        it "should save the token in redis as a key with 'auth:'" do
            expect(@redis.exists("auth:#{@token}")).to be true 
        end
        it "should save the user secret in redis as a value" do
            expect(@redis.get("auth:#{@token}")).to eq(@secret)
        end
        it "should add a TTL to of 3 hours to the token" do
            expect(@redis.ttl("auth:#{@token}")).to eq(60*60*3)
        end
    end
    context "#create_token" do #user_id, user_secret, oauth
        before(:each) do
            @id = 1
            @secret = "SECRET"
            @oauth = {"github" => "GHB"}
            @username = "ADAM11"
            @token = @account.create_token @id, @secret, @oauth, @username
            @payload, @header = JWT.decode @token, Digest::MD5.hexdigest("#{ENV['WIRED7_HMAC']}:#{@secret}"), true, { :verify_iat => true, :verify_jti => true, :algorithm => 'HS256' }
        end
        context "context jwt" do
            it "should contain user_id" do
                expect(@payload["user_id"]).to eq(@id)
            end
            it "should contain oauth token" do
                expect(@payload["oauth"]).to eq(@oauth)
            end
            it "should contain username" do
                expect(@payload["username"]).to eq(@username)
            end
        end
    end
    context "#get_secret" do
        before(:each) do
            @token = "123456"
            @secret = "ABCDEF"
            @redis.set("auth:#{@token}", @secret)
        end
        it "should return value for token key" do
            expect(@account.get_secret @token).to eq(@secret)
        end
    end
    context "#validate_token" do
        before(:each) do
            @id = 1
            @secret = "SECRET"
            @oauth = {"github" => "GHB"}
            @username = "ADAM11"
        end
        context "valid token" do
            before(:each) do
                @valid_token = @account.create_token @id, @secret, @oauth, @username
                @payload = @account.validate_token @valid_token, @secret
            end
            it "should return nil" do
                expect(@payload).to_not be nil
            end
            context "payload" do
                it "should return user_id" do
                    expect(@payload["user_id"]).to eq(@id)
                end
                it "should return oauth" do
                    expect(@payload["oauth"]).to eq(@oauth)
                end
                it "should return iat" do
                    expect(@payload["iat"]).to be <= Time.now.to_i
                end
                it "should return jti" do
                    expect(@payload["jti"]).to eq(Digest::MD5.hexdigest("#{Digest::MD5.hexdigest("#{ENV['WIRED7_HMAC']}:#{@secret}")}:#{@payload["iat"]}"))
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
                        :oauth =>  {"github" => "GHB"} 
                    }
                    token = JWT.encode payload, Digest::MD5.hexdigest("#{ENV['WIRED7_HMAC']}:#{@secret}"), "HS256"
                    expect(@account.validate_token token, @secret).to be nil
                end
            end
            context "invalid secret" do
                it "should return nil" do
                    payload = {
                        :iat => Time.now.to_i,
                        :jti => Digest::MD5.hexdigest("#{Digest::MD5.hexdigest("#{ENV['WIRED7_HMAC']}:#{@secret}")}:#{Time.now.to_i}"),
                        :user_id => 1,
                        :oauth =>  {"github" => "GHB"}                  
                    }
                    token = JWT.encode payload, Digest::MD5.hexdigest("#{ENV['WIRED7_HMAC']}:#{@secret}"), "HS256"
                    expect(@account.validate_token token, "ABC").to be nil
                end
            end
        end
    end
    context "#delete_token" do
        before(:each) do
            @token = "123456"
            @secret = "ABCDEF"
            @redis.set("auth:#{@token}", @secret)
            @res = @account.delete_token @token 
        end
        it "should return OK" do
            expect(@res).to be true
        end
        it "should delete the token" do
            expect(@redis.exists("auth:#{@token}")).to be false
        end
    end
    context "#has_account" do
        context "account does not exist" do
            it "should return 0" do
                expect(@account.has_account "adam0@wired7.com").to eq(0)
            end
        end
        context "account exists" do
            fixtures :users
            it "should return user id" do
                expect(@account.has_account users(:adam).email).to eq(users(:adam).id)
            end
        end
    end
    context "#create" do
        context "email does exist" do
            fixtures :users
            before(:each) do
                @res = @account.create users(:adam).email, users(:adam).username, "something.png"
            end
            it "should return -1" do
                expect(@res).to eq(nil)
            end
            it "should not create a new record in the users table" do
                expect(@mysql_client.query("select * from users where email = '#{users(:adam).email}'").count).to eq(1)
            end
        end
        context "email does not exist" do
            before(:each) do
                @email = "adam0@wired7.com"
                @username = "adam"
                @avatar = "avatar.png"
                @res = @account.create @email, @username, @avatar
                @mysql = @mysql_client.query("select * from users").first
            end
            context "users table" do
                it "should include email" do
                    expect(@mysql["email"]).to eq(@email)
                end
                it "should include username" do
                    expect(@mysql["username"]).to eq(@username)
                end
                it "should include admin = 0" do
                    expect(@mysql["admin"]).to eq(0)
                end
                it "should include avatar" do
                    expect(@mysql["avatar"]).to eq(@avatar)
                end
                it "should include lock = false" do
                    expect(@mysql["lock"]).to be 0
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
                it "should include include lock" do
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
                @res = @account.record_login @id, @ip
                @record = @mysql_client.query("select * from logins where id = #{users(:adam).id}").first
            end
            context "response" do
                it "should return id of login" do
                    expect(@res).to eq 1
                end
            end
            context "logins table" do
                it "should save user id" do
                    expect(@record["id"]).to eq(@id)
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
end

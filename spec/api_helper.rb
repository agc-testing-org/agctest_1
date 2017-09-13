# Additional setup for API tests
RSpec.configure do |config|
    config.before(:each) do
        if @CREATE_TOKENS # if users fixtures are loaded
            # admin user
            admin_password = "adam12345"
            admin_email = users(:adam_admin).email
            post "/login", { :password => admin_password, :email => admin_email }.to_json
            res = JSON.parse(last_response.body)
            @admin_w7_token = res["access_token"]

            # confirmed user w/ github token
            @user = users(:adam_confirmed).id
            email = users(:adam_confirmed).email
            post "/login", { :password => admin_password, :email => email }.to_json
            res = JSON.parse(last_response.body)
            @non_admin_w7_token = res["access_token"]

            code = "123"
            access_token = "ACCESS123"

            Octokit::Client.any_instance.stub(:exchange_code_for_token) { JSON.parse({
                :access_token => access_token
            }.to_json, object_class: OpenStruct) }


            @username = "ADAM123"
            Octokit::Client.any_instance.stub(:login) { @username }
            post "/session/github", {:grant_type => "github", :auth_code => code }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
            res = JSON.parse(last_response.body)
            @non_admin_w7_token = res["access_token"] # new token generated with github sign in
          
            @uri = "test/#{@username}/git-repo-log.git"
            @uri_master = "test/#{@username}/DEMO.git"
            @sha = "b218bd1da7786b8beece26fc2e6b2fa240597969"
            @sha_anonymous = "18feb3c1568fe4cac7bf4eae543bf1a5ee8405b8"
        end
    end
end

def prepare_repo
    # setup fake/local "github" repo
    if @uri && @uri_master && @username
        FileUtils.rm_rf('repositories/')
        %x( mkdir "test/#{@username}")
        %x( mkdir "test/#{ENV['INTEGRATIONS_GITHUB_ORG']}")
        %x( rm -rf #{@uri})
        %x( cp -rf test/git-repo #{@uri_master}; mv #{@uri_master}/git #{@uri_master}/.git)
        %x( cp -rf test/git-repo #{@uri}; mv #{@uri}/git #{@uri}/.git)
    end
end

def destroy_repo
    if @uri && @uri_master && @username
        %x( rm -rf #{@uri}) 
        %x( rm -rf #{@uri_master})
        %x( rm -rf "test/#{@username}")
        %x( rm -rf "test/#{ENV['INTEGRATIONS_GITHUB_ADMIN_USER']}")
        %x( rm -rf "test/#{ENV['INTEGRATIONS_GITHUB_ORG']}")
        %x( rm -rf repositories/*)
    end
end

# Additional setup for API tests

def prepare_tokens
    # admin user
    admin_password = "adam12345"
    admin_email = users(:adam_admin).email
    post "/login", { :password => admin_password, :email => admin_email }.to_json
    res = JSON.parse(last_response.body)
    @admin_w7_token = res["w7_token"]

    # confirmed user w/ github token
    @user = users(:adam_confirmed).id
    email = users(:adam_confirmed).email
    post "/login", { :password => admin_password, :email => email }.to_json
    res = JSON.parse(last_response.body)
    @non_admin_w7_token = res["w7_token"]

    code = "123"
    access_token = "ACCESS123"

    Octokit::Client.any_instance.stub(:exchange_code_for_token) { JSON.parse({
        :access_token => access_token
    }.to_json, object_class: OpenStruct) }


    @username = "ADAM123"
    Octokit::Client.any_instance.stub(:login) { @username }
    post "/session/github", {:grant_type => "github", :auth_code => code }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
    res = JSON.parse(last_response.body)
    @non_admin_github_token = res["github_token"]

end

def prepare_repo
    # setup fake/local "github" repo
    FileUtils.rm_rf('repositories/')
    %x( mkdir "test/#{@username}")
    @uri = "test/#{@username}/git-repo-log.git"
    @uri_master = "test/ADAM123/DEMO.git"
    @sha = "b218bd1da7786b8beece26fc2e6b2fa240597969"
    %x( rm -rf #{@uri})
    %x( cp -rf test/git-repo #{@uri_master}; mv #{@uri_master}/git #{@uri_master}/.git)
    %x( cp -rf test/git-repo #{@uri}; mv #{@uri}/git #{@uri}/.git)
end

def destroy_repo
    config.after(:each) do
        %x( rm -rf #{@uri}) 
        %x( rm -rf #{@uri_master})
        %x( rm -rf "test/#{@username}")
        %x( rm -rf repositories/*)
    end
end

shared_examples_for "unauthorized" do
    before(:each) do
        follow_redirect!
    end
    it "should return a 401" do
        expect(last_response.status).to eq 401
    end
    it "should return unauthorized message" do
        expect(JSON.parse(last_response.body)["error"]).to eq("unauthorized")
    end
end

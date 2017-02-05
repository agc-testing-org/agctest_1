require_relative '../spec_helper'

describe ".Issue" do
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
        @repo = Repo.new
        FileUtils.rm_rf('repositories/')
        @uri = "test/git-repo-log"
        @sha = "b218bd1da7786b8beece26fc2e6b2fa240597969"
        %x( rm -rf #{@uri})                 
        %x( cp -rf test/git-repo #{@uri}; mv #{@uri}/git #{@uri}/.git)
    end
    after(:each) do
        %x( rm -rf #{@uri}) 
        %x( rm -rf repositories/*) 
    end
    context "#name" do
        it "should return a unique name w/ adjective - color - number" do
            expect(@repo.name.split("-").length).to be >= 2
        end
    end
    context "#create" do
        #covered in API test
    end
    context "#get_repository" do
        fixtures :users, :projects
        context "repository exists" do           
            fixtures :contributors
            it "should return last contribution" do
                expect(@repo.get_repository users(:adam_confirmed).id, projects(:demo).id).to eq(contributors(:adam_confirmed_1))
            end
        end
        context "repository does not exist" do
            it "should return nil" do
                expect(@repo.get_repository users(:adam_confirmed).id, projects(:demo).id).to eq(nil)
            end
        end
    end

    context "#clone" do
        before(:each) do
            @sprint_state_id = 99
            @contributor_id = "adam123"
            @branch = "master"
            @res = @repo.clone @uri, @sprint_state_id, @contributor_id, @branch
        end
        context "success" do
            it "should return a git object" do
                expect(@res).to_not be nil
            end
            it "should clone a github repo in the repositories dir" do
                expect(File.directory?("repositories/#{@sprint_state_id}_#{@contributor_id}")).to be true
            end
            it "should pull the #{@branch} branch" do
                expect(%x( cd repositories/#{@sprint_state_id}_#{@contributor_id}; git branch )).to include("master")
            end
        end
        context "failure" do
            context "already exists" do
                it "should return nil" do
                    expect(@repo.clone @uri, @sprint_state_id, @contributor_id, "master").to be nil
                end
            end
        end
    end
    context "#log_head" do
        before(:each) do
            @sprint_state_id = 99
            @contributor_id = "adam123"
            @branch = "master"
            @repository = @repo.clone @uri, @sprint_state_id, @contributor_id, @branch
            @commit_message = "newest commit"
            %x( cd "repositories/#{@sprint_state_id}_#{@contributor_id}"; git branch; echo '1' > tmp; git add .; git commit -m"#{@commit_message};")
            @res = @repo.log_head @repository
        end
        it "should return the most recent commit message" do
            expect("#{@res}\n").to eq(%x(cd repositories/#{@sprint_state_id}_#{@contributor_id}; git rev-parse HEAD))
        end
    end
    context "#add_remote" do
        before(:each) do
            @sprint_state_id = 99
            @contributor_id = "adam123"
            @branch = "master"          
            @repository = @repo.clone @uri, @sprint_state_id, @contributor_id, @branch
            @remote = "https://agc-testing:123456@github.com/agc-testing/a-repo"
            @name = "adam-remote"
            @res = @repo.add_remote @repository, @remote, @name
        end
        context "success" do
            it "should return a git object" do
                expect(@res).to be true
            end
            it "should add a remote" do
                expect(%x( cd "repositories/#{@sprint_state_id}_#{@contributor_id}"; git remote -v )).to include("#{@name}\t#{@remote} (push)")
            end
        end
        context "failure" do
            it "should return nil" do
                expect(@repo.add_remote @repository, @remote, @name).to be false 
            end
        end
    end

    context "#add_remote" do
        before(:each) do
            @sprint_state_id = 99
            @contributor_id = "adam123" 
            @branch = "master"          
            @repository = @repo.clone @uri, @sprint_state_id, @contributor_id, @branch
            @remote = "https://agc-testing:123456@github.com/agc-testing/a-repo"
            @name = "adam-remote"
            @res = @repo.add_remote @repository, @remote, @name
        end                                                                                                                     
        context "success" do
            it "should return a git object" do 
                expect(@res).to be true                         
            end                                                             
            it "should add a remote" do                 
                expect(%x( cd "repositories/#{@sprint_state_id}_#{@contributor_id}"; git remote -v )).to include("#{@name}\t#{@remote} (push)")
            end                                                                         
        end                                                     
        context "failure" do        
            it "should return nil" do               
                expect(@repo.add_remote @repository, @remote, @name).to be false       
            end                                                                     
        end                                                 
    end 

    context "#add_branch" do
        before(:each) do
            @sprint_state_id = 99
            @contributor_id = "adam123"
            @branch = "master"
            @repository = @repo.clone @uri, @sprint_state_id, @contributor_id, @branch
            @new_branch = "develop"
            @res = @repo.add_branch @repository, @new_branch
        end
        context "success" do
            it "should return something, not nil" do
                expect(@res).to be true
            end 
            it "should add resource_id branch" do
                expect(%x( cd "repositories/#{@sprint_state_id}_#{@contributor_id}"; git branch )).to include("* #{@new_branch}\n")
            end
        end
        context "already on branch" do
            it "should not return error" do 
                expect(@repo.add_branch @repository, @new_branch).to be true
            end 
        end 
    end

    context "#push_remote" do
        before(:each) do
            @sprint_state_id = 99
            @contributor_id = "adam123" 
            @branch = "master"          
            @repository = @repo.clone @uri, @sprint_state_id, @contributor_id, @branch
            @uri_b = "test/git-repo-log-b"
            %x( cp -rf test/git-repo #{@uri_b}; mv #{@uri_b}/git #{@uri_b}/.git)
            @new_branch = "branch"
            @repo.add_branch @repository, @new_branch
            @commit_message = "newest commit"
            %x( cd "repositories/#{@sprint_state_id}_#{@contributor_id}"; git branch; echo '1' > tmp; git add .; git commit -m"#{@commit_message};")
            @name = "adam-remote"
            @repo.add_remote @repository, @uri_b, @name
            @res = @repo.push_remote @repository, @name, @new_branch
        end        
        after(:each) do
            %x( rm -rf #{@uri_b})
        end
        context "success" do
            it "should return true" do
                expect(@res).to be true
            end
            it "should send last commit to remote" do
                expect(%x( cd #{@uri_b}; git checkout #{@new_branch}; git log)).to include(@commit_message)
            end
        end
    end 
    context "#log_head_remote" do
        before(:each) do
            branch = 1
            owner = "agc-testing"
            repository = "actest"
            secret = "abc"

            body = { 
                :name=>branch, 
                :commit=>{
                    :sha=>"11d97224b71da54cd32d8ec6f7bf7da6317d07ed"
                }
            }

            @body = JSON.parse(body.to_json, object_class: OpenStruct)

            Octokit::Client.any_instance.stub(:branch => @body)
            @res = @repo.log_head_remote secret, owner, repository, branch
        end
        it "should return the last hash of a remote repository" do
            expect(@res).to eq(@body.commit.sha) 
        end
    end
    
end

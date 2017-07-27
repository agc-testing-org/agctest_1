# Integrations

### Installation
    
    Install node (https://nodejs.org/en/download/)

    cd integrations-client

    sudo npm install n -g
    sudo n 7.10.0

    sudo npm -g install npm@next
    npm install -g ember-cli@2.13
    npm install
    npm install -g bower

    vi ~/.bashrc
    
    ### INTEGRATIONS ENV VARS
    export INTEGRATIONS_HOST="https://localhost:3000" #https://wired7.com
    export INTEGRATIONS_ID_CIPHER="12345678"
    export INTEGRATIONS_S3_BUCKET="app.wired7.com"
    export INTEGRATIONS_GITHUB_CLIENT_ID=""
    export INTEGRATIONS_GITHUB_CLIENT_SECRET=""
    export INTEGRATIONS_GITHUB_URL="https://github.com"
    export INTEGRATIONS_GITHUB_ADMIN_USER="agc-testing" #wired7-ateam
    export INTEGRATIONS_GITHUB_ADMIN_SECRET=""
    export INTEGRATIONS_LINKEDIN_CLIENT_ID=""
    export INTEGRATIONS_LINKEDIN_CLIENT_SECRET=""
    export INTEGRATIONS_MYSQL_USERNAME="root"
    export INTEGRATIONS_MYSQL_PASSWORD="123456"
    export INTEGRATIONS_MYSQL_HOST="localhost"
    export INTEGRATIONS_REDIS_HOST="127.0.0.1"
    export INTEGRATIONS_REDIS_PORT="6379"
    export INTEGRATIONS_REDIS_DB=1
    export INTEGRATIONS_HMAC=""
    export INTEGRATIONS_EMAIL_ADDRESS=""
    export INTEGRATIONS_EMAIL_PASSWORD=""
    export INTEGRATIONS_SIDEKIQ_HOST=true
    export INTEGRATIONS_SIDEKIQ_USERNAME="adam"
    export INTEGRATIONS_SIDEKIQ_PASSWORD="123456"
    export INTEGRATIONS_INITIAL_USER_EMAIL="adamwired7+admin@gmail.com" #this is to allow us to sign in once we first deploy

    if [ "$RACK_ENV" == "test" ]; then
        export INTEGRATIONS_GITHUB_URL="test"
        export INTEGRATIONS_REDIS_DB=2
        export INTEGRATIONS_EMAIL_ADDRESS="" # !!KEEP EMPTY
    fi 

    for INTEGRATIONS_HMAC, use the value output by: ruby -rsecurerandom -e "puts SecureRandom.hex(32)" 

    Install rvm: https://rvm.io/rvm/install
    Install homebrew: http://brew.sh/
    brew install mysql
    brew install redis
    gem install bundler

    export RACK_ENV=test
    source ~/.bashrc
    bundle install
    bundle exec rake db:create
    bundle exec rake db:migrate

    export RACK_ENV=development
    source ~/.bashrc
    bundle exec rake db:create
    bundle exec rake db:migrate

    NOTE: to create a project in the application, you must be an admin user.  Doing this as a normal user will return a 401 and redirect you to the login page.

### Github Setup

- Create a test Github account
- Setup a developer application for this Github account (https://github.com/settings/developers)
- Set authorization callback to https://localhost:3000/callback/github
- Save client ID as INTEGRATIONS_GITHUB_CLIENT_ID and client secret as INTEGRATIONS_GITHUB_CLIENT_SECRET in your ~/.bashrc
- Save your username in the ~/.bashrc as INTEGRATIONS_GITHUB_ADMIN_USER
- Setup a personal token for that user as well (https://github.com/settings/tokens)
- Save this in the ~/.bashrc as INTEGRATIONS_GITHUB_ADMIN_SECRET

### LinkedIn Setup

- Create a test Linkedin Account
- Setup a developer application for this Linkedin Account (https://www.linkedin.com/developer/apps)
- Set authorized redirect URL to https://localhost:3000/callback/linkedin
- Save client ID as INTEGRATIONS_LINKEDIN_CLIENT_ID and client secret as INTEGRATIONS_LINKEDIN_CLIENT_SECRET in your ~/.bashrc

### Running

Shell 1 (if redis server is not running)

    redis-server

Shell 2 (project root)
    
    rvm use ruby-2.3.0
    bundle install
    export RACK_ENV=development
    source ~/.bashrc
    whenever --update-crontab #probably don't need this every time, but will help if it changes
    bundle exec rake db:migrate
    passenger start --ssl --ssl-certificate localhost.crt --ssl-certificate-key localhost.key --port 3001 --ssl-port 3000 

Shell 3 (project root)

    rvm use ruby-2.3.0
    bundle install
    export RACK_ENV=development
    source ~/.bashrc
    bundle exec sidekiq -c5 -e $RACK_ENV -r ./lib/api/integrations.rb 

Shell 3

    cd integrations-client
    bower install
    npm install
    source ~/.bashrc
    ember build --watch

Browser
    
    Go to https://localhost:3000
    If this is your first deploy use the forgot password option on the application and you will receive an email at INTEGRATIONS_INITIAL_USER_EMAIL 

Monitoring Background Jobs

    Go to https://localhost:3000/sidekiq
    Enter the vars you have set for INTEGRATIONS_SIDEKIQ_USERNAME and INTEGRATIONS_SIDEKIQ_PASSWORD


### Deployment

Shell 1:

Ensure production server has the following (in addition to the vars listed above for the bashrc):

    export AWS_ACCESS_KEY_ID=''
    export AWS_SECRET_ACCESS_KEY=''
    export AWS_REGION='us-west-2'

These are used to connect the backend to the s3 assets

eb deploy

Shell 2:
 
    source ~/.bashrc_wired7_production (includes RACK_ENV, Github/Linkedin client IDs, host)
    ember deploy production
    ember deploy:list production
    ember deploy:activate production --revision #####

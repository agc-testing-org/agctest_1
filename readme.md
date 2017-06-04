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
- Save client ID as INTEGRATIONS_GITHUB_CLIENT_ID and client secret as INTEGRATIONS_GITHUB_CLIENT_SECRET in your ~/.bashrc (vars found below)
- Save your username in the ~/.bashrc as INTEGRATIONS_GITHUB_ADMIN_USER
- Setup a personal token for that user as well (https://github.com/settings/tokens)
- Save this in the ~/.bashrc as INTEGRATIONS_GITHUB_ADMIN_SECRET


### Running

Shell 1 (if redis server is not running)

    redis-server

Shell 2 (project root)
    
    rvm use ruby-2.4.0
    bundle install
    export RACK_ENV=development
    source ~/.bashrc
    whenever --update-crontab #probably don't need this every time, but will help if it changes
    bundle exec rake db:migrate
    passenger start --ssl --ssl-certificate localhost.crt --ssl-certificate-key localhost.key --port 3001 --ssl-port 3000 

Shell 3

    cd integrations-client
    bower install
    npm install
    source ~/.bashrc
    ember build --watch

Browser
    
    Go to https://localhost:3000

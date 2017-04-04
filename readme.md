# Integrations

### Installation
    
    Install node (https://nodejs.org/en/download/)

    cd integrations-client

    sudo npm install n -g
    sudo n 0.12.2

    sudo npm -g install npm@next
    npm install -g ember-cli@2.10
    npm install

    vi ~/.bashrc
    
    ### INTEGRATIONS ENV VARS
    export INTEGRATIONS_HOST="https://localhost:3000" #https://wired7.com
    export INTEGRATIONS_GITHUB_CLIENT_ID=""
    export INTEGRATIONS_GITHUB_CLIENT_SECRET=""
    export INTEGRATIONS_GITHUB_URL="https://github.com"
    export INTEGRATIONS_GITHUB_ADMIN_USER="agc-testing" #wired7-ateam
    export INTEGRATIONS_GITHUB_ADMIN_SECRET=""
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

    export RACK_ENV=test
    source ~/.bashrc
    bundle install
    rake db:create
    rake db:migrate

    export RACK_ENV=development
    source ~/.bashrc
    rake db:create
    rake db:migrate


### Github Setup

- Create a test Github account
- Setup a developer application for this Github account (https://github.com/settings/developers)
- Save client ID as INTEGRATIONS_GITHUB_CLIENT_ID and client secret as INTEGRATIONS_GITHUB_CLIENT_SECRET in your ~/.bashrc (vars found below)
- Save your username in the ~/.bashrc as INTEGRATIONS_GITHUB_ADMIN_USER
- Setup a personal token for that user as well (https://github.com/settings/tokens)
- Save this in the ~/.bashrc as INTEGRATIONS_GITHUB_ADMIN_SECRET


### Running

Shell 1 (if redis server is not running)

    redis-server

Shell 2 (project root)
    
    rvm use ruby-2.2.3
    bundle install
    export RACK_ENV=development
    source ~/.bashrc
    rake db:migrate
    passenger start --ssl --ssl-certificate localhost.crt --ssl-certificate-key localhost.key --port 3001 --ssl-port 3000 

Shell 3

    cd integrations-client
    bower install
    npm install
    source ~/.bashrc
    ember build --watch

Browser
    
    Go to https://localhost:3000

# Integrations


### Installation
    
    cd integrations-client
    sudo npm -g install npm@next
    npm install -g ember-cli@2.10
    npm install

    vi ~/.bashrc
    
    ### INTEGRATIONS ENV VARS
    export INTEGRATIONS_HOST="http://localhost:3000" #https://wired7.com
    export INTEGRATIONS_GITHUB_CLIENT_ID="94a26b248fde7aef732b" #c6d1f8245795c6612187 
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
        export INTEGRATIONS_REDIS_DB=2
        export INTEGRATIONS_EMAIL_ADDRESS="" # !!KEEP EMPTY
    fi  

### Running

Shell 1 (project root)

    rvm use ruby-2.2.3
    bundle install
    export RACK_ENV=development
    source ~/.bashrc
    rake db:migrate
    passenger start

Shell 2

    cd integrations-client
    bower install
    source ~/.bashrc
    ember build --watch

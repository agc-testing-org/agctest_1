# Integrations


### Installation
    
    cd integrations-client
    sudo npm -g install npm@next
    npm install -g ember-cli@2.10

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
    if [ "$RACK_ENV" == "test" ]; then
        export INTEGRATIONS_REDIS_DB=2
    fi

### Running

    ember s

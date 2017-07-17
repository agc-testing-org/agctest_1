require 'sinatra'
require 'sinatra/activerecord'
require 'watir'
require 'rack/test'
require 'database_cleaner'
require 'rails/all'
require 'rspec/rails'
require 'redis'
require 'webmock/rspec'
require 'ostruct'
require 'sidekiq/testing'

require File.join(File.dirname(__FILE__), '..', 'lib/api/integrations.rb')

set :environment, :test
set :run, false
set :raise_errors, true
set :logging, true

Sidekiq::Testing.inline!

def app
    Integrations 
end

include Obfuscate

RSpec.configure do |config|
    config.include Rack::Test::Methods
    config.fixture_path = File.expand_path("../../test/fixtures", __FILE__)

    #    ActiveRecord::Base.logger = Logger.new(STDOUT)

    config.use_transactional_fixtures = false

    config.before(:suite) do
        DatabaseCleaner.strategy = :truncation
        DatabaseCleaner.clean_with(:truncation)
        DatabaseCleaner.start
        DatabaseCleaner.clean
    end

    config.after(:suite) do
        DatabaseCleaner.strategy = :truncation
        DatabaseCleaner.clean_with(:truncation)
        DatabaseCleaner.start
        DatabaseCleaner.clean
    end

    config.before(:all) do
        @mysql_client = Mysql2::Client.new(
            :host => ENV['INTEGRATIONS_MYSQL_HOST'],
            :username => ENV['INTEGRATIONS_MYSQL_USERNAME'],
            :password => ENV['INTEGRATIONS_MYSQL_PASSWORD'],
            :database => "integrations_#{ENV['RACK_ENV']}"
        )

        @redis = Redis.new(:host => ENV['INTEGRATIONS_REDIS_HOST'], :port => ENV['INTEGRATIONS_REDIS_PORT'], :db => ENV['INTEGRATIONS_REDIS_DB'])
    end

    config.after(:each) do
        DatabaseCleaner.strategy = :transaction
        DatabaseCleaner.clean_with(:truncation)
        DatabaseCleaner.clean
        Redis.new(:host => ENV['INTEGRATIONS_REDIS_HOST'], :port => ENV['INTEGRATIONS_REDIS_PORT'], :db => ENV['INTEGRATIONS_REDIS_DB']).flushdb
    end

end


shared_examples_for "unauthorized" do
    it "should return a 401" do
        expect(last_response.status).to eq 401
    end
    it "should return unauthorized message" do
        expect(JSON.parse(last_response.body)["errors"][0]["detail"]).to eq "unauthorized"
    end
end

shared_examples_for "unauthorized_admin" do
    it "should return a 400" do
        expect(last_response.status).to eq 400
    end
    it "should return unauthorized message" do
        expect(JSON.parse(last_response.body)["errors"][0]["detail"]).to eq "this action requires additional authorization"
    end
end

shared_examples_for "not_found" do
    it "should return a 404" do
        expect(last_response.status).to eq 404
    end                     
    it "should return not found message" do
        expect(JSON.parse(last_response.body)["errors"][0]["detail"]).to eq "not found"
    end                         
end

shared_examples_for "error" do |message|
    it "should return a 400" do
        expect(last_response.status).to eq 400
    end                                                     
    it "should return an error message" do
        expect(JSON.parse(last_response.body)["errors"][0]["detail"]).to eq message
    end                                                 
end

shared_examples_for "created" do 
    it "should return a 201" do
        expect(last_response.status).to eq 201
    end     
end 

shared_examples_for "ok" do
    it "should return a 200" do
        expect(last_response.status).to eq 200
    end                 
end


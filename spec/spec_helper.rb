require 'sinatra'
require 'sinatra/activerecord'
require 'watir-webdriver'
require 'rack/test'
require 'database_cleaner'
require 'rails/all'
require 'rspec/rails'
require 'redis'
require 'webmock/rspec'
require 'ostruct'

require File.join(File.dirname(__FILE__), '..', 'lib/api/integrations.rb')

set :environment, :test
set :run, false
set :raise_errors, true
set :logging, true

def app
    Integrations 
end

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

    config.after(:each) do
        DatabaseCleaner.strategy = :transaction
        DatabaseCleaner.clean_with(:truncation)
        DatabaseCleaner.clean
        Redis.new(:host => ENV['INTEGRATIONS_REDIS_HOST'], :port => ENV['INTEGRATIONS_REDIS_PORT'], :db => ENV['INTEGRATIONS_REDIS_DB']).flushdb
    end

end


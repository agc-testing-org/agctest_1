require 'sinatra/activerecord'

class ConnectionState < ActiveRecord::Base
    validates_uniqueness_of :name
end
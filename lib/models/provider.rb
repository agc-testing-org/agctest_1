require 'sinatra/activerecord'

class Provider < ActiveRecord::Base
    validates_uniqueness_of :name
end

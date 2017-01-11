require 'sinatra/activerecord'

class Role < ActiveRecord::Base
    validates_uniqueness_of :name
end

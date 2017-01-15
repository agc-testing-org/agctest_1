require 'sinatra/activerecord'

class Contributor < ActiveRecord::Base
    validates_uniqueness_of :name
end

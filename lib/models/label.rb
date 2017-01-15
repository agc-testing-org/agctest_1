require 'sinatra/activerecord'

class Label < ActiveRecord::Base
    validates_uniqueness_of :name
end

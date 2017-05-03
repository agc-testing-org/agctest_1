require 'sinatra/activerecord'

class Role < ActiveRecord::Base
    validates_uniqueness_of :name
    has_many :user_roles
end

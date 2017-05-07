require 'sinatra/activerecord'

class User < ActiveRecord::Base
    validates_uniqueness_of :email
    has_many :sprints
    has_many :contributors
    has_many :comments
    has_many :votes
end

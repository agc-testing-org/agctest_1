require 'sinatra/activerecord'

class User < ActiveRecord::Base
    validates_uniqueness_of :email
    has_many :sprints
    has_many :contributors
    has_many :user_skillsets
    has_many :user_notifications
    has_many :user_contributors
    has_many :user_connections
end

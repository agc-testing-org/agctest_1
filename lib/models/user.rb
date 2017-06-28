require 'sinatra/activerecord'

class User < ActiveRecord::Base
    validates_uniqueness_of :email
    has_many :sprints
    has_many :contributors
    has_many :teams
    has_many :user_teams
    has_many :comments
    has_many :votes
    has_one :user_profile
    has_many :user_skillsets
    has_many :user_notifications
    has_many :user_connections
end

require 'sinatra/activerecord'

class Team < ActiveRecord::Base
    validates_uniqueness_of :name
    has_many :user_teams
    belongs_to :user
    belongs_to :plan
end

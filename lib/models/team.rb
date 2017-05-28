require 'sinatra/activerecord'

class Team < ActiveRecord::Base
    #validates_uniqueness_of :name #we could probably allow non-uniques in this case (for now)
    has_many :user_teams
end

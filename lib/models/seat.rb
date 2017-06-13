require 'sinatra/activerecord'

class Seat < ActiveRecord::Base
    belongs_to :user_teams
    belongs_to :plan
end

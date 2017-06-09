require 'sinatra/activerecord'

class Plan < ActiveRecord::Base
    belongs_to :team
    belongs_to :seat
end

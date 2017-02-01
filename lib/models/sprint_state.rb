require 'sinatra/activerecord'

class SprintState < ActiveRecord::Base
    belongs_to :sprint
    belongs_to :state
end

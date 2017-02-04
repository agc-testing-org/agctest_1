require 'sinatra/activerecord'

class SprintState < ActiveRecord::Base
    belongs_to :sprint
    belongs_to :state
    has_many :states
end

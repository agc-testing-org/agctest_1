require 'sinatra/activerecord'

class Sprint < ActiveRecord::Base
    belongs_to :project
    belongs_to :user
    has_many :sprint_states
end

require 'sinatra/activerecord'

class State < ActiveRecord::Base
    validates_uniqueness_of :name
    has_many :sprint_timelines
    belongs_to :sprint_states
end

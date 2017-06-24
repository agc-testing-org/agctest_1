require 'sinatra/activerecord'

class SprintTimeline < ActiveRecord::Base
    belongs_to :project
    belongs_to :sprint
    belongs_to :user
    belongs_to :state
    belongs_to :label
    belongs_to :sprint_state
    belongs_to :comment
    belongs_to :vote
    belongs_to :contributor
end

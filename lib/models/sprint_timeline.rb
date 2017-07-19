require 'sinatra/activerecord'

class SprintTimeline < ActiveRecord::Base
    include Obfuscate

    def user_id
        encrypt self[:user_id]
    end
    belongs_to :project
    belongs_to :sprint
    belongs_to :user
    belongs_to :state
    belongs_to :sprint_state
    belongs_to :next_sprint_state, :class_name => "SprintState"
    belongs_to :comment
    belongs_to :vote
    belongs_to :contributor
end

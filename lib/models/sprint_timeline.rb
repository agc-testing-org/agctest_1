require 'sinatra/activerecord'

class SprintTimeline < ActiveRecord::Base
    belongs_to :project
end

require 'sinatra/activerecord'

class Contributor < ActiveRecord::Base
    belongs_to :sprint_state
    belongs_to :user
    belongs_to :project
end

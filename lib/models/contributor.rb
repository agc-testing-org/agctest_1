require 'sinatra/activerecord'

class Contributor < ActiveRecord::Base
    belongs_to :sprint_state
    belongs_to :user
    belongs_to :project
    has_many :comments
    has_many :votes
end

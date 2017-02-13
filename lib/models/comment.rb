require 'sinatra/activerecord'

class Comment < ActiveRecord::Base
    belongs_to :contributor
    belongs_to :sprint_state
    belongs_to :user
end

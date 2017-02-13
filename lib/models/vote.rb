require 'sinatra/activerecord'

class Vote < ActiveRecord::Base
    belongs_to :contributor
    belongs_to :sprint_state
    belongs_to :user
    validates_uniqueness_of :user, scope: :sprint_state
end

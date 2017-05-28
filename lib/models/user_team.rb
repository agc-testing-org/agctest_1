require 'sinatra/activerecord'

class UserTeam < ActiveRecord::Base
    validates_uniqueness_of :user_id, scope: :team_id
    belongs_to :team
    belongs_to :sender
    belongs_to :user
end


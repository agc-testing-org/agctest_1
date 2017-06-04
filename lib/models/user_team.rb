require 'sinatra/activerecord'

class UserTeam < ActiveRecord::Base
    validates_uniqueness_of :user_email, scope: :team_id
    belongs_to :team
    belongs_to :sender, :class_name => "User"
    belongs_to :user
end


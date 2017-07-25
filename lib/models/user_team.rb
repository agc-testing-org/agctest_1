require 'sinatra/activerecord'

class UserTeam < ActiveRecord::Base
    include Obfuscate

    def user_id
        encrypt self[:user_id]
    end
    def sender_id
        encrypt self[:sender_id]
    end
    validates_uniqueness_of :user_email, scope: :team_id, conditions: -> { where.not(profile_id: nil) }
    belongs_to :team
    belongs_to :sender, :class_name => "User"
    belongs_to :profile, :class_name => "User"
    belongs_to :user
    belongs_to :seat
end


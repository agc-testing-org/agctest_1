require 'sinatra/activerecord'

class UserTeam < ActiveRecord::Base
    include Obfuscate

    def user_id
        encrypt self[:user_id]
    end
    def sender_id
        encrypt self[:sender_id]
    end
    def profile_id
        encrypt self[:profile_id]
    end
    
    validates_uniqueness_of :user_email, scope: :team_id, unless: Proc.new { |invite| invite.profile_id } #conditions: -> { where(profile_id: nil) }
    validates_uniqueness_of :user_email, scope: [:team_id, :profile_id], if: Proc.new { |invite| invite.profile_id }

    belongs_to :team
    belongs_to :sender, :class_name => "User"
    belongs_to :profile, :class_name => "User"
    belongs_to :user
    belongs_to :seat
end


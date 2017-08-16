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
    
    validates_uniqueness_of :user_email, scope: :team_id, unless: Proc.new { |invite| invite.profile_id }, :message => "this email address has an existing invitation" #conditions: -> { where(profile_id: nil) } # for invites
    validates_uniqueness_of :user_email, scope: [:team_id, :profile_id], if: Proc.new { |invite| invite.profile_id }, :message => "this email address has an existing invitation" # for shares
    validates_uniqueness_of :user_email, conditions: -> { where("expires > ?", Time.now) }, :message => "this user is exclusively working with another team" # for invites where a user is working with another team

    belongs_to :team
    belongs_to :sender, :class_name => "User"
    belongs_to :profile, :class_name => "User"
    belongs_to :user
    belongs_to :seat
end


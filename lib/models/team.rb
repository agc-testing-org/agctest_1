require 'sinatra/activerecord'

class Team < ActiveRecord::Base
    include Obfuscate

    def user_id
        encrypt self[:user_id]
    end
    validates_uniqueness_of :name, scope: :company, :message => "this team name already exists for your company"
    has_many :user_teams
    has_many :jobs
    belongs_to :user
    belongs_to :plan
end

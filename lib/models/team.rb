require 'sinatra/activerecord'

class Team < ActiveRecord::Base
    include Obfuscate

    def user_id
        encrypt self[:user_id]
    end
    validates_uniqueness_of :name
    has_many :user_teams
    belongs_to :user
    belongs_to :plan
end

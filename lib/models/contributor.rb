require 'sinatra/activerecord'

class Contributor < ActiveRecord::Base
    include Obfuscate

    def user_id
        encrypt self[:user_id]
    end

    belongs_to :sprint_state
    belongs_to :user
    belongs_to :project
    has_many :comments
    has_many :votes
end

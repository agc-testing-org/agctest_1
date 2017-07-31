require 'sinatra/activerecord'

class Comment < ActiveRecord::Base
    include Obfuscate

    def user_id
        encrypt self[:user_id]
    end 

    belongs_to :contributor
    belongs_to :sprint_state
    belongs_to :user
    has_many :votes
end

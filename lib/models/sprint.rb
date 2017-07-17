require 'sinatra/activerecord'

class Sprint < ActiveRecord::Base
    include Obfuscate

    def user_id
        encrypt self[:user_id]
    end

    belongs_to :project
    belongs_to :user
    has_many :sprint_states
end

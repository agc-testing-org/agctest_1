require 'sinatra/activerecord'

class SprintState < ActiveRecord::Base
    include Obfuscate

    def arbiter_id
        encrypt self[:arbiter_id]
    end

    belongs_to :sprint
    belongs_to :state
    has_many :states
    has_many :contributors
    belongs_to :contributor
end

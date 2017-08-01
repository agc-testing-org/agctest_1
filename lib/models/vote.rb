require 'sinatra/activerecord'

class Vote < ActiveRecord::Base
    include Obfuscate

    def user_id
        encrypt self[:user_id]
    end
    belongs_to :contributor
    belongs_to :sprint_state
    belongs_to :user
    belongs_to :comment
end

require 'sinatra/activerecord'

class UserProfile < ActiveRecord::Base
    include Obfuscate

    def user_id
        encrypt self[:user_id]
    end
    belongs_to :user
    has_one :user_position
end

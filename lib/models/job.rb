require 'sinatra/activerecord'

class Job < ActiveRecord::Base
    include Obfuscate

    def user_id
        encrypt self[:user_id]
    end

    has_many :sprints
    belongs_to :user
    belongs_to :team

end

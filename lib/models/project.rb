require 'sinatra/activerecord'

class Project < ActiveRecord::Base
    include Obfuscate

    def user_id
        encrypt self[:user_id]
    end

    has_many :sprints
    has_many :sprint_timelines
    has_many :contributors
    belongs_to :user
end

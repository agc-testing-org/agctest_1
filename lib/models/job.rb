require 'sinatra/activerecord'

class Job < ActiveRecord::Base
    include Obfuscate

    def user_id
        encrypt self[:user_id]
    end

    #validates_uniqueness_of :title, scope: :link
    belongs_to :sprint
    has_many :sprints
    belongs_to :user
    belongs_to :team
    belongs_to :role
end

require 'sinatra/activerecord'

class TeamNotification < ActiveRecord::Base
    include Obfuscate

    belongs_to :team
    belongs_to :user
    belongs_to :sprint_timeline
    validates_uniqueness_of :sprint_timeline_id, scope: :team_id
end

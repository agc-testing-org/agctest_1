require 'sinatra/activerecord'

class UserNotification < ActiveRecord::Base
    include Obfuscate

    def user_id
        encrypt self[:user_id]
    end
    belongs_to :user
    belongs_to :sprint_timeline
    validates_uniqueness_of :sprint_timeline_id, scope: :user_id 
end

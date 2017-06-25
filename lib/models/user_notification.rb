require 'sinatra/activerecord'

class UserNotification < ActiveRecord::Base
    belongs_to :user
    validates_uniqueness_of :sprint_timeline_id, scope: :user_id 
end

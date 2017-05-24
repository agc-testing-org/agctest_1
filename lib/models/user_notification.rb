require 'sinatra/activerecord'

class UserNotification < ActiveRecord::Base
    belongs_to :notification
    belongs_to :user
    validates_uniqueness_of :notifications_id, scope: :user_id 
end
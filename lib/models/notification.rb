require 'sinatra/activerecord'

class Notification < ActiveRecord::Base
    has_many :user_notifications
    validates_uniqueness_of :sprint_timeline_id
    belongs_to :sprint
end
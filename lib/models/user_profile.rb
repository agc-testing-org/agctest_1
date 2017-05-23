require 'sinatra/activerecord'

class UserProfile < ActiveRecord::Base
    belongs_to :user
    has_one :user_position
end

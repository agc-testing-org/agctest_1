require 'sinatra/activerecord'

class UserPosition < ActiveRecord::Base
    belongs_to :user_profile
end

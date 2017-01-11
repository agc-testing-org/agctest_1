require 'sinatra/activerecord'

class UserRole < ActiveRecord::Base
    validates_uniqueness_of :user_id, scope: :role_id
end

require 'sinatra/activerecord'

class RoleState < ActiveRecord::Base
    belongs_to :role
    belongs_to :state
end

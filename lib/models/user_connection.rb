require 'sinatra/activerecord'

class UserConnection < ActiveRecord::Base
    belongs_to :user
    has_many :connection_states
end
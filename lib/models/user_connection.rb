require 'sinatra/activerecord'

class UserConnection < ActiveRecord::Base
    belongs_to :user
    belongs_to :contact
    has_many :connection_states
end
require 'sinatra/activerecord'

class Sprint < ActiveRecord::Base
    belongs_to :user
end

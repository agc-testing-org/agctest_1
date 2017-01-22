require 'sinatra/activerecord'

class Sprint < ActiveRecord::Base
    belongs_to :project
    belongs_to :user
end

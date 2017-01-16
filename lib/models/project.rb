require 'sinatra/activerecord'

class Project < ActiveRecord::Base
    has_many :sprints
end

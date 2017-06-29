require 'sinatra/activerecord'

class Project < ActiveRecord::Base
    has_many :sprints
    has_many :sprint_timelines
    has_many :contributors
    belongs_to :user
end

require 'sinatra/activerecord'

class Skillset < ActiveRecord::Base
    has_many :sprint_skillsets
end

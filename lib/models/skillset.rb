require 'sinatra/activerecord'

class Skillset < ActiveRecord::Base
    has_many :sprint_skillsets
    has_many :user_skillsets
end

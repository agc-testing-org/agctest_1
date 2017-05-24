require 'sinatra/activerecord'

class UserContributor < ActiveRecord::Base
	belongs_to :contributor
    belongs_to :user
	validates_uniqueness_of :contributors_id, scope: :user_id 
end

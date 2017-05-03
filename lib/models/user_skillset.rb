require 'sinatra/activerecord'

class UserSkillset < ActiveRecord::Base
	validates_uniqueness_of :user_id, scope: :skillset_id
    belongs_to :skillset
    belongs_to :user
end

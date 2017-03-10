require 'sinatra/activerecord'

class SprintSkillset < ActiveRecord::Base
    validates_uniqueness_of :sprint_id, scope: :skillset_id
    belongs_to :skillset
    belongs_to :sprint
end

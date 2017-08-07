require 'sinatra/activerecord'

class JobRole < ActiveRecord::Base
    validates_uniqueness_of :job_id, scope: :role_id
    belongs_to :role
    belongs_to :job
end

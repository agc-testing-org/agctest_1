require 'sinatra/activerecord'

class UserSkillset < ActiveRecord::Base
    include Obfuscate

    def user_id
        encrypt self[:user_id]
    end
    validates_uniqueness_of :user_id, scope: :skillset_id
    belongs_to :skillset
    belongs_to :user
end

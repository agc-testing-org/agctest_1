require 'sinatra/activerecord'

class UserRole < ActiveRecord::Base
    include Obfuscate

    def user_id
        encrypt self[:user_id]
    end
    validates_uniqueness_of :user_id, scope: :role_id
    belongs_to :role
    belongs_to :user
end

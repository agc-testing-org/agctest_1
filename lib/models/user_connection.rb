require 'sinatra/activerecord'

class UserConnection < ActiveRecord::Base
    include Obfuscate

    def user_id
        encrypt self[:user_id]
    end
    def contact_id
        encrypt self[:contact_id]
    end

    belongs_to :user
    belongs_to :contact, :class_name => "User"
end

require 'sinatra/activerecord'

class Job < ActiveRecord::Base
    include Obfuscate

    def user_id
        encrypt self[:user_id]
    end

    has_many :sprints
    has_one :user
    has_one :team

    #    attr_accessor :public_id
    #    def attributes
    #        super.merge('public_id' => self.public_id)
    #    end

    #    def public_id
    #        decrypt self[:id]
    #    end

    #    def self.find(id)
    #        puts id.inspect
    #        id = decrypt id
    #        super 
    #    end
end

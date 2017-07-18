require 'sinatra/activerecord'

class User < ActiveRecord::Base
    include Obfuscate

    def id
        encrypt self[:id]
    end

    validates_uniqueness_of :email
    has_many :sprints
    has_many :contributors
    has_many :teams
    has_many :user_teams
    has_many :comments
    has_many :votes
    has_one :user_profile
    has_many :user_skillsets
    has_many :user_notifications
    has_many :user_connections
    has_many :projects

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

require 'sinatra/activerecord'

class Vote < ActiveRecord::Base
    include Obfuscate

    def user_id
        encrypt self[:user_id]
    end
    belongs_to :contributor
    belongs_to :sprint_state
    belongs_to :user
    belongs_to :comment
    validates_uniqueness_of :user, scope: [:sprint_state, :comment], conditions: -> { where(comment: nil) }
    validates_uniqueness_of :user, scope: [:comment, :flag], conditions: -> { where.not(comment: nil)} {where.not(flag: false) }
    validates_uniqueness_of :user, scope: [:comment, :flag], conditions: -> { where.not(comment: nil)} {where(flag: true) }

end

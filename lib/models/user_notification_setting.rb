require 'sinatra/activerecord'

class UserNotificationSetting < ActiveRecord::Base
    include Obfuscate

    def user_id
        encrypt self[:user_id]
    end
    validates_uniqueness_of :user_id, scope: :notification_id
    belongs_to :notification
    belongs_to :user
end

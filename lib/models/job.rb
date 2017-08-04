require 'sinatra/activerecord'

ActiveSupport::Inflector.inflections(:en) do |inflect|
    inflect.irregular 'job', 'jobs'
end

class Job < ActiveRecord::Base
    include Obfuscate

    def user_id
        encrypt self[:user_id]
    end

    has_many :sprints
    has_one :user
    has_one :team

end

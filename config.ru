require_relative './lib/api/integrations.rb'
require 'sidekiq/web'

if ENV['INTEGRATIONS_SIDEKIQ_USERNAME']
    map '/sidekiq' do
        use Rack::Auth::Basic, "Protected Area" do |username, password|
            Rack::Utils.secure_compare(::Digest::SHA256.hexdigest(username), ::Digest::SHA256.hexdigest(ENV["INTEGRATIONS_SIDEKIQ_USERNAME"])) &
                Rack::Utils.secure_compare(::Digest::SHA256.hexdigest(password), ::Digest::SHA256.hexdigest(ENV["INTEGRATIONS_SIDEKIQ_PASSWORD"]))
        end

        run Sidekiq::Web
    end
end

map '/' do
    run Integrations
end

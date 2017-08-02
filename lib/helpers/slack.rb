class Slack
    
    def initialize
        @http = Net::HTTP.new("hooks.slack.com",443)
        @http.use_ssl = true
        @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    
    # no need to return anything
    def post_accepted user_team
        if ENV['INTEGRATIONS_SLACK_WEBHOOK'] && (ENV['INTEGRATIONS_SLACK_WEBHOOK'].include? "/")
            begin
                request = Net::HTTP::Post.new("/services/#{ENV['INTEGRATIONS_SLACK_WEBHOOK']}")
                json = {
                    :text => "#{user_team.user.first_name} (#{user_team.user.email}) joined team #{user_team.team.name}; invited by #{user_team.sender.first_name} (#{user_team.sender.email})" 
                }
                request.body = json.to_json
                response = @http.request(request)
            rescue => e
                puts e
            end
        end
    end
end

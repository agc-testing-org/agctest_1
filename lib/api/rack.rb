module Rack
    module Throttle

        class HourlyRegister < Hourly
             def allowed?(request)
                return true
             end
        end

        #        class HourlyPosts < Hourly
        #            def allowed?(request)
        #               return true unless ((request.request_method == "POST") && ((request.path_info.include? "/votes") || (request.path_info.include? "/comments")||(request.path_info.include? "/skillsets")||(request.path_info.include? "/session")))
        #                super request
        #            end
        #        end
        class Limiter   
            def http_error(code, message = nil, headers = {})
                [403, {'Content-Type' => 'application/json; charset=utf-8'}.merge(headers),
                 [{ :message => message}.to_json]]            
            end

            def cache_set(key, value)
                begin
                    if cache.get(key)
                        cache.incr(key)
                    else
                        cache.setex(key,60*60,value) #1 hour
                    end
                rescue => e
                    puts e
                end
            end
        end         

    end                     
end


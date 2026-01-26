#gen_token
#generates auth_token which can be used for continous imports. Will prevent audit log flooding.
#use this method first before calling e.g. import functions.
module Gen_Token
    extend self
    def logon_for_token(user, pw)
        method = '/api/v2/auth/login'
        url = URI.join($current_server, method)
        params = { "username" => user, "password" => pw }
        req = Net::HTTP::Post.new(url)
        req['Accept'] = 'application/json'
        req['Content-Type'] = 'application/json'
        req.body = params.to_json
        
        res = Net::HTTP.start(url.hostname, url.port, use_ssl: true) do |http|
            http.request(req)
        end
        res_string = JSON.parse(res.body)
        
        case res.code.to_i
        when 200
            $token = res_string['data']['attributes']['token']
            $token_expires = res_string['data']['attributes']['exp']
        when 400..404
            error_msg = res_data.dig('errors', 0, 'detail') || 'Unknown error'  # fallback if detail is missing
            error_code = res_data.dig('errors', 0, 'status') || res.code        # use HTTP status if not in response
            puts "Code: #{error_code}: #{error_msg}"                            # the "#{}"-constructor can only be used in strings with double quotes
            return { success: false, error: error_msg, code: error_code }
          else  
            puts "Unexpected error: #{res.code} - #{res.body}" # response is outside of expected range
            return { success: false, error: res.body, code: res.code }
          end
       
    rescue StandardError => e
        puts "Request failed: #{e.message}"
        return { success: false, error: e.message }
    end
end


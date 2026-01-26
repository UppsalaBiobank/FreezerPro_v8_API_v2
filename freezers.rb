#freezer functions

module Freezer
    extend self
    
    def retreive_freezer(uid) #return specific freezer
        method = '/api/v2/freezers/'
        url = URI.join($current_server, method, uid)
        req = Net::HTTP::Get.new(url)
        req['Authorization'] = $token
        req['Accept'] = 'application/json'
        res = Net::HTTP.start(url.hostname, url.port, use_ssl: true) do |http|
            http.request(req)
        end
        
        res_string = JSON.parse(res.body)
        case res.code.to_i
        when 200
            $freezer_id = res_string['data']['id']
            $freezer_name = res_string['data']['attributes']['name']
            $freezer_desc = res_string['data']['attributes']['description']
            $freezer_barcode = res_string['data']['attributes']['barcode_tag']
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

    def create_freezer(name, desc)
        method = '/api/v2/freezers/'
        url = URI.join($current_server, method)
        params = { 'freezer': {'name': name, 'description': desc }}
        req = Net::HTTP::Post.new(url)
        req['Authorization'] = $token
        req['Accept'] = 'application/json'
        req['Content-Type'] = 'application/json'
        req.body = params.to_json
        res = Net::HTTP.start(url.hostname, url.port, use_ssl: true) do |http|
            http.request(req)
        end
        
        res_string = JSON.parse(res.body)
        case res.code.to_i
        when 201
            $freezer_id = res_string['data']['id']
            $freezer_name = res_string['data']['attributes']['name']
            $freezer_desc = res_string['data']['attributes']['description']
            $freezer_barcode = res_string['data']['attributes']['barcode_tag']
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

    def update_freezer(uid, new_name, new_desc, new_barcode_tag)
        method = '/api/v2/freezers/'
        url = URI.join($current_server, method, uid)
        params = { 'freezer': { 'name': new_name, 'description': new_desc, 'barcode_tag': new_barcode_tag}}
        req = Net::HTTP::Patch.new(url)
        req['Authorization'] = $token
        req['Accept'] = 'application/json'
        req['Content-Type'] = 'application/json'
        res = Net::HTTP.start(url.hostname, url.port, use_ssl: true) do |http|
            http.request(req)
        end
        
        res_string = JSON.parse(res.body)
        case res.code.to_i
        when 200
            $freezer_id = res_string['data']['id']
            $freezer_name = res_string['data']['attributes']['name']
            $freezer_desc = res_string['data']['attributes']['description']
            $freezer_barcode = res_string['data']['attributes']['barcode_tag']
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

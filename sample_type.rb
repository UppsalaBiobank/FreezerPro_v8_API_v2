#Sample type functions - FreezerPro API v2

module Sample_Type
    extend self
    
    # Retrieve sample type by ID
    # @param uid [String, Integer] Sample type ID
    # @return [Hash] Respond with :success, :data/:error
    def retreive_sample_type(uid) #return specific sample source. 
        method = '/api/v2/sample_types/'
        url = URI.join($current_server, method, uid.to_s)
        req = Net::HTTP::Get.new(url)
        req['Authorization'] = $token
        req['Accept'] = 'application/json'
        res = Net::HTTP.start(url.hostname, url.port, use_ssl: true) do |http|
            http.request(req)
        end
        
        res_string = JSON.parse(res.body)
        case res.code.to_i
        when 200
            sample_type_id = res_string['data']['id']
            $sample_type_name = res_string['data']['attributes']['name']
            sample_type_desc = res_string['data']['attributes']['description']
            #puts 'sample type id: ' + sample_type_id + '. Sample type name: ' + $sample_type_name# + '. Sample type desc: ' + sample_type_desc
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

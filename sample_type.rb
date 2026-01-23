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
            error_msg = res_string['errors'][0]['detail']
            error_code = res_string['errors'][0]['status']
            puts "Code: #{error_code}: #{error_msg}" ## the #{} constructor can only be used in strings with double quotes
        else  
            puts "Unexpected error: #{res.code} - #{res.body}"
        end
    end

end


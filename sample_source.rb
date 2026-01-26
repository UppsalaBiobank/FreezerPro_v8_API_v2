#Samples functions FP8 API v2

module Sample
    extend self
    
    # Retrieve a specific sample by ID
    # @param uid [Int, String] Sample ID
    # @return [Hash] Response hash with :success, :data/:error
    def retrieve_sample(uid)
        method = '/api/v2/samples/'
        url = URI.join($current_server, method, uid.to_s)
        req = Net::HTTP::Get.new(url)
        req['Authorization'] = $token
        req['Accept'] = 'application/json'
        req['Content-Type'] = 'application/json'
        res = Net::HTTP.start(url.hostname, url.port, use_ssl: true) do |http|
          http.request(req)
        end 
        
        res_data = JSON.parse(res.body) 
        case res.code.to_i
        when 200
            data = res_data['data']
            # Store data in global variables
            $sample_id = data['id']
            $sample_name = data.dig('attributes', 'name')
            $sample_desc = data.dig('attributes', 'description')
            $sample_created_at = data.dig('attributes', 'created_at')
            $sample_updated_at = data.dig('attributes', 'updated_at')   
            # Extract relationships
            $sample_type_id = data.dig('relationships', 'sample_type', 'data', 'id')
            $sample_source_id = data.dig('relationships', 'sample_source', 'data', 'id')
            $sample_parent_id = data.dig('relationships', 'parent', 'data', 'id')
            $sample_owner_id = data.dig('relationships', 'owner', 'data', 'id') 
            # Extract array relationships
            $sample_vials_id = data.dig('relationships', 'vials', 'data')&.map { |v| v['id'] } || []
            $sample_udfs_id = data.dig('relationships', 'udfs', 'data')&.map { |u| u['id'] } || []
            $sample_groups_id = data.dig('relationships', 'sample_groups', 'data')&.map { |g| g['id'] } || []   
            puts "Successfully retrieved sample: #{$sample_name} (ID: #{$sample_id})"
            return { success: true, data: data }
        
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

    # Update a specific sample
    # @param uid [String, Integer] Sample ID
    # @param name [String, nil] New sample name
    # @param description [String, nil] New description
    # @param sample_type_id [Integer, String, nil] New sample type ID
    # @param udfs [Array, nil] Array of UDF hashes with 'name' and 'value' keys
    # @return [Hash] Response hash with :success, :data/:error
    def update_sample(uid, name: nil, description: nil, sample_type_id: nil, udfs: nil)
        method = '/api/v2/samples/'
        url = URI.join($current_server, method, uid)
        
        # Build the request body according to API spec
        sample_params = {}
        sample_params['name'] = name unless name.nil? || name.strip.empty?
        sample_params['description'] = description unless description.nil? || description.strip.empty?
        sample_params['sample_type_id'] = sample_type_id.to_i unless sample_type_id.nil? || (sample_type_id.is_a?(String) && sample_type_id.strip.empty?)
        sample_params['udfs'] = udfs unless udfs.nil? || udfs.empty?
        
        # Check if we have any params to send
        if sample_params.empty?
            puts "No parameters provided for update"
            return { success: false, error: "No parameters provided" }
        end

        # Wrap in 'sample' key as per API spec
        request_body = { 'sample' => sample_params }

        req = Net::HTTP::Patch.new(url)
        req['Authorization'] = $token
        req['Accept'] = 'application/json'
        req['Content-Type'] = 'application/json'
        req.body = request_body.to_json

        res = Net::HTTP.start(url.hostname, url.port, use_ssl: true) do |http|
            http.request(req)
        end

        res_data = JSON.parse(res.body)

        case res.code.to_i
        when 200
            data = res_data['data']
            # Update all global variables with the latest data
            $sample_id = data['id']
            $sample_name = data.dig('attributes', 'name')
            $sample_desc = data.dig('attributes', 'description')
            $sample_created_at = data.dig('attributes', 'created_at')
            $sample_updated_at = data.dig('attributes', 'updated_at')

            # Extract relationships
            $sample_type_id = data.dig('relationships', 'sample_type', 'data', 'id')
            $sample_source_id = data.dig('relationships', 'sample_source', 'data', 'id')
            $sample_parent_id = data.dig('relationships', 'parent', 'data', 'id')
            $sample_owner_id = data.dig('relationships', 'owner', 'data', 'id')

            # Extract array relationships
            $sample_vials_id = data.dig('relationships', 'vials', 'data')&.map { |v| v['id'] } || []
            $sample_udfs_id = data.dig('relationships', 'udfs', 'data')&.map { |u| u['id'] } || []
            $sample_groups_id = data.dig('relationships', 'sample_groups', 'data')&.map { |g| g['id'] } || []

            puts "Successfully updated sample: #{$sample_name} (ID: #{$sample_id})"
            return { success: true, data: data }
      
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
    

    # Create a new sample
    # @param name [String] Sample name (required)
    # @param sample_type_id [Integer, String] Sample type ID (required)
    # @param description [String, nil] Sample description (optional)
    # @param udfs [Array, nil] Array of UDF hashes with 'name' and 'value' keys (optional)
    # @return [Hash] Response hash with :success, :data/:error
    def create_sample(name:, sample_type_id:, description: nil, udfs: nil)
        method = '/api/v2/samples'
        url = URI.join($current_server, method)

        # Build the request body according to API spec
        sample_params = { 'name' => name, 'sample_type_id' => sample_type_id.to_i }
        sample_params['description'] = description unless description.nil? || description.strip.empty?
        sample_params['udfs'] = udfs unless udfs.nil? || udfs.empty?
        
        # Wrap in 'sample' key as per API spec
        request_body = { 'sample' => sample_params }

        req = Net::HTTP::Post.new(url)
        req['Authorization'] = $token
        req['Accept'] = 'application/json'
        req['Content-Type'] = 'application/json'
        req.body = request_body.to_json
        
        res = Net::HTTP.start(url.hostname, url.port, use_ssl: true) do |http|
            http.request(req)
        end

        res_data = JSON.parse(res.body)

        case res.code.to_i
        when 201
            data = res_data['data']
            sample_id = data['id']
            sample_name = data.dig('attributes', 'name')
            puts "Successfully created sample: #{sample_name} (ID: #{sample_id})"
            return { success: true, data: data, id: sample_id }
        
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
  

    # Get all samples with optional filtering
    # @param filters [Hash, nil] Hash of filter parameters (e.g., { 'name_cont' => 'Bacteria' })
    # @return [Hash] Response hash with :success, :data/:error
    def list_samples(filters: nil)
        method = '/api/v2/samples'
        url = URI.join($current_server, method)
        
        # Add filter parameters if provided
        if filters && !filters.empty?
        query_params = filters.map { |k, v| "filter[#{k}]=#{URI.encode_www_form_component(v)}" }.join('&')
        url.query = query_params
        end
    
        req = Net::HTTP::Get.new(url)
        req['Authorization'] = $token
        req['Accept'] = 'application/json'
        req['Content-Type'] = 'application/json'
    
        res = Net::HTTP.start(url.hostname, url.port, use_ssl: true) do |http|
            http.request(req)
        end
    
        res_data = JSON.parse(res.body)
    
        case res.code.to_i
        when 200
            samples = res_data['data']
            puts "Retrieved #{samples.length} sample(s)"
            return { success: true, data: samples, count: samples.length }
        
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
end  ##end of module


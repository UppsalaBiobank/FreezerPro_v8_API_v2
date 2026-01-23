# Sample Source functions - FreezerPro API V2

module SampleSource
    extend self
  
    # Retrieve a specific sample source by ID
    # @param uid [String, Integer] Sample Source ID
    # @return [Hash] Response hash with :success, :data/:error
    def retrieve_sample_source(uid)
      method = '/api/v2/sample_sources/'
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
        $sample_source_id = data['id']
        $sample_source_name = data.dig('attributes', 'name')
        $sample_source_desc = data.dig('attributes', 'description')
        $sample_source_enabled = data.dig('attributes', 'enabled')
        $sample_source_created_at = data.dig('attributes', 'created_at')
        $sample_source_updated_at = data.dig('attributes', 'updated_at')
        
        # Extract relationships
        $sample_source_type_id = data.dig('relationships', 'sample_source_type', 'data', 'id')
        $sample_source_samples_id = data.dig('relationships', 'samples', 'data')&.map { |s| s['id'] } || []
        $sample_source_udfs_id = data.dig('relationships', 'udfs', 'data')&.map { |u| u['id'] } || []
        
        puts "Successfully retrieved sample source: #{$sample_source_name} (ID: #{$sample_source_id})"
        puts "  Type ID: #{$sample_source_type_id}, Enabled: #{$sample_source_enabled}"
        return { success: true, data: data }
        
      when 401
        error_msg = res_data.dig('errors', 0, 'detail') || 'Unauthorized'
        error_code = res_data.dig('errors', 0, 'status') || res.code
        puts "Error #{error_code}: #{error_msg}"
        return { success: false, error: error_msg, code: error_code }
        
      when 403
        error_msg = res_data.dig('errors', 0, 'detail') || 'Invalid rights - no permission to access this sample source'
        error_code = res_data.dig('errors', 0, 'status') || res.code
        puts "Error #{error_code}: #{error_msg}"
        return { success: false, error: error_msg, code: error_code }
        
      when 404
        error_msg = res_data.dig('errors', 0, 'detail') || 'Sample source not found'
        error_code = res_data.dig('errors', 0, 'status') || res.code
        puts "Error #{error_code}: #{error_msg}"
        return { success: false, error: error_msg, code: error_code }
        
      else
        puts "Unexpected error: #{res.code} - #{res.body}"
        return { success: false, error: res.body, code: res.code }
      end
      
    rescue StandardError => e
      puts "Request failed: #{e.message}"
      return { success: false, error: e.message }
    end
  
    # Update a specific sample source
    # @param uid [String, Integer] Sample Source ID
    # @param name [String, nil] New name
    # @param description [String, nil] New description
    # @param udfs [Array, nil] Array of UDF hashes with 'name' and 'value' keys
    # @return [Hash] Response hash with :success, :data/:error
    def update_sample_source(uid, name: nil, description: nil, udfs: nil)
      method = '/api/v2/sample_sources/'
      url = URI.join($current_server, method, uid.to_s)
      
      # Build the request body according to API spec
      sample_source_params = {}
      sample_source_params['name'] = name unless name.nil? || name.strip.empty?
      sample_source_params['description'] = description unless description.nil? || description.strip.empty?
      sample_source_params['udfs'] = udfs unless udfs.nil? || udfs.empty?
      
      # Check if we have any params to send
      if sample_source_params.empty?
        puts "No parameters provided for update"
        return { success: false, error: "No parameters provided" }
      end
      
      # Wrap in 'sample_source' key as per API spec
      request_body = { 'sample_source' => sample_source_params }
      
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
        $sample_source_id = data['id']
        $sample_source_name = data.dig('attributes', 'name')
        $sample_source_desc = data.dig('attributes', 'description')
        $sample_source_enabled = data.dig('attributes', 'enabled')
        $sample_source_created_at = data.dig('attributes', 'created_at')
        $sample_source_updated_at = data.dig('attributes', 'updated_at')
        
        # Extract relationships
        $sample_source_type_id = data.dig('relationships', 'sample_source_type', 'data', 'id')
        $sample_source_samples_id = data.dig('relationships', 'samples', 'data')&.map { |s| s['id'] } || []
        $sample_source_udfs_id = data.dig('relationships', 'udfs', 'data')&.map { |u| u['id'] } || []
        
        puts "Successfully updated sample source: #{$sample_source_name} (ID: #{$sample_source_id})"
        return { success: true, data: data }
        
      when 400
        error_msg = res_data.dig('errors', 0, 'detail') || 'Invalid parameters'
        error_code = res_data.dig('errors', 0, 'status') || res.code
        puts "Error #{error_code}: #{error_msg}"
        return { success: false, error: error_msg, code: error_code }
        
      when 401
        error_msg = res_data.dig('errors', 0, 'detail') || 'Unauthorized'
        error_code = res_data.dig('errors', 0, 'status') || res.code
        puts "Error #{error_code}: #{error_msg}"
        return { success: false, error: error_msg, code: error_code }
        
      when 403
        error_msg = res_data.dig('errors', 0, 'detail') || 'Restricted access - no permission to update this sample source'
        error_code = res_data.dig('errors', 0, 'status') || res.code
        puts "Error #{error_code}: #{error_msg}"
        return { success: false, error: error_msg, code: error_code }
        
      when 404
        error_msg = res_data.dig('errors', 0, 'detail') || 'Sample source not found'
        error_code = res_data.dig('errors', 0, 'status') || res.code
        puts "Error #{error_code}: #{error_msg}"
        return { success: false, error: error_msg, code: error_code }
        
      else
        puts "Unexpected error: #{res.code} - #{res.body}"
        return { success: false, error: res.body, code: res.code }
      end
      
    rescue StandardError => e
      puts "Request failed: #{e.message}"
      return { success: false, error: e.message }
    end
  
    # Create a new sample source
    # @param name [String] Sample source name (required)
    # @param sample_source_type_id [Integer, String] Sample source type ID (required)
    # @param description [String, nil] Sample source description (optional)
    # @param udfs [Array, nil] Array of UDF hashes with 'name' and 'value' keys (optional)
    # @return [Hash] Response hash with :success, :data/:error
    def create_sample_source(name:, sample_source_type_id:, description: nil, udfs: nil)
      method = '/api/v2/sample_sources'
      url = URI.join($current_server, method)
  
      # Build the request body according to API spec
      sample_source_params = {
        'name' => name,
        'sample_source_type_id' => sample_source_type_id.to_s
      }
      
      sample_source_params['description'] = description unless description.nil? || description.strip.empty?
      sample_source_params['udfs'] = udfs unless udfs.nil? || udfs.empty?
      
      # Wrap in 'sample_source' key as per API spec
      request_body = { 'sample_source' => sample_source_params }
  
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
        source_id = data['id']
        source_name = data.dig('attributes', 'name')
        puts "Successfully created sample source: #{source_name} (ID: #{source_id})"
        return { success: true, data: data, id: source_id }
        
      when 400
        error_msg = res_data.dig('errors', 0, 'detail') || 'Invalid parameters'
        error_code = res_data.dig('errors', 0, 'status') || res.code
        puts "Error #{error_code}: #{error_msg}"
        return { success: false, error: error_msg, code: error_code }
        
      when 401
        error_msg = res_data.dig('errors', 0, 'detail') || 'Unauthorized'
        error_code = res_data.dig('errors', 0, 'status') || res.code
        puts "Error #{error_code}: #{error_msg}"
        return { success: false, error: error_msg, code: error_code }
        
      when 403
        error_msg = res_data.dig('errors', 0, 'detail') || 'Invalid rights - no permission to create sample sources'
        error_code = res_data.dig('errors', 0, 'status') || res.code
        puts "Error #{error_code}: #{error_msg}"
        return { success: false, error: error_msg, code: error_code }
        
      else
        puts "Unexpected error: #{res.code} - #{res.body}"
        return { success: false, error: res.body, code: res.code }
      end
      
    rescue StandardError => e
      puts "Request failed: #{e.message}"
      return { success: false, error: e.message }
    end
  
    # Delete a sample source
    # Note: Can only delete if no samples are associated with it
    # @param uid [String, Integer] Sample Source ID
    # @return [Hash] Response hash with :success, :error
    def delete_sample_source(uid)
      method = '/api/v2/sample_sources/'
      url = URI.join($current_server, method, uid.to_s)
      
      req = Net::HTTP::Delete.new(url)
      req['Authorization'] = $token
      req['Accept'] = 'application/json'
      req['Content-Type'] = 'application/json'
      
      res = Net::HTTP.start(url.hostname, url.port, use_ssl: true) do |http|
        http.request(req)
      end
      
      case res.code.to_i
      when 204
        puts "Successfully deleted sample source (ID: #{uid})"
        return { success: true }
        
      when 400
        res_data = JSON.parse(res.body)
        error_msg = res_data.dig('errors', 0, 'detail') || 'Cannot delete - sample source is in use'
        error_code = res_data.dig('errors', 0, 'status') || res.code
        puts "Error #{error_code}: #{error_msg}"
        return { success: false, error: error_msg, code: error_code }
        
      when 401
        res_data = JSON.parse(res.body)
        error_msg = res_data.dig('errors', 0, 'detail') || 'Unauthorized'
        error_code = res_data.dig('errors', 0, 'status') || res.code
        puts "Error #{error_code}: #{error_msg}"
        return { success: false, error: error_msg, code: error_code }
        
      when 403
        res_data = JSON.parse(res.body)
        error_msg = res_data.dig('errors', 0, 'detail') || 'Restricted access - no permission to delete this sample source'
        error_code = res_data.dig('errors', 0, 'status') || res.code
        puts "Error #{error_code}: #{error_msg}"
        return { success: false, error: error_msg, code: error_code }
        
      when 404
        res_data = JSON.parse(res.body)
        error_msg = res_data.dig('errors', 0, 'detail') || 'Sample source not found'
        error_code = res_data.dig('errors', 0, 'status') || res.code
        puts "Error #{error_code}: #{error_msg}"
        return { success: false, error: error_msg, code: error_code }
        
      else
        puts "Unexpected error: #{res.code} - #{res.body}"
        return { success: false, error: res.body, code: res.code }
      end
      
    rescue StandardError => e
      puts "Request failed: #{e.message}"
      return { success: false, error: e.message }
    end
  
    # Get all sample sources with optional filtering
    # @param filters [Hash, nil] Hash of filter parameters
    # @return [Hash] Response hash with :success, :data/:error
    #
    # @example Filter by name
    #   list_sample_sources(filters: { 'name_eq' => 'Sample Source Test' })
    #
    # @example Filter by description
    #   list_sample_sources(filters: { 'description_cont' => 'Description' })
    #
    # @example Filter by number of samples
    #   list_sample_sources(filters: { 'samples_lt' => '20' })
    #
    # @example Filter by creation date
    #   list_sample_sources(filters: { 'created_eq' => '10/07/2022' })
    #
    # @example Filter by UDF
    #   list_sample_sources(filters: { 'udf_Address_cont' => 'Street' })
    def list_sample_sources(filters: nil)
      method = '/api/v2/sample_sources'
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
        sources = res_data['data']
        puts "Retrieved #{sources.length} sample source(s)"
        return { success: true, data: sources, count: sources.length }
        
      when 401
        error_msg = res_data.dig('errors', 0, 'detail') || 'Unauthorized'
        error_code = res_data.dig('errors', 0, 'status') || res.code
        puts "Error #{error_code}: #{error_msg}"
        return { success: false, error: error_msg, code: error_code }
        
      when 403
        error_msg = res_data.dig('errors', 0, 'detail') || 'Invalid rights - no permission to view sample sources'
        error_code = res_data.dig('errors', 0, 'status') || res.code
        puts "Error #{error_code}: #{error_msg}"
        return { success: false, error: error_msg, code: error_code }
        
      else
        puts "Unexpected error: #{res.code} - #{res.body}"
        return { success: false, error: res.body, code: res.code }
      end
      
    rescue StandardError => e
      puts "Request failed: #{e.message}"
      return { success: false, error: e.message }
    end
  
    # Create a subscription for sample source changes
    # This sets up a webhook to receive notifications when sample sources change
    # @param callback_url [String] URL to receive webhook notifications
    # @return [Hash] Response hash with :success, :data/:error
    def create_sample_source_subscription(callback_url)
      method = '/api/v2/sample_sources/sample_source_change'
      url = URI.join($current_server, method)
      
      request_body = { 'callback_url' => callback_url }
      
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
        puts "Successfully created sample source subscription"
        puts "Callback URL: #{callback_url}"
        return { success: true, data: data }
        
      else
        puts "Unexpected error: #{res.code} - #{res.body}"
        return { success: false, error: res.body, code: res.code }
      end
      
    rescue StandardError => e
      puts "Request failed: #{e.message}"
      return { success: false, error: e.message }
    end
  
    # Convenience method: Get sample sources by type
    # @param type_id [String, Integer] Sample source type ID
    # @return [Hash] Response hash with :success, :data/:error
    def get_sources_by_type(type_id)
      list_sample_sources(filters: { 'type_id_eq' => type_id.to_s })
    end
  
    # Convenience method: Search sample sources by name
    # @param name_fragment [String] Partial name to search for
    # @return [Hash] Response hash with :success, :data/:error
    def search_by_name(name_fragment)
      list_sample_sources(filters: { 'name_cont' => name_fragment })
    end
  end

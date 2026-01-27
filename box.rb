#box functions

module Box
  extend self
    
  # Retrieve a specific box by ID
  # @param uid [Int, String] Box ID
  # @return [Hash] response hash with :success, :data/:error
  def retreive_box(uid) #return specific box
    method = '/api/v2/boxes/'
    url = URI.join($current_server, method, uid.to_s)
    req = Net::HTTP::Get.new(url)
    req['Authorization'] = $token
    req['Accept'] = 'application/json'
    res = Net::HTTP.start(url.hostname, url.port, use_ssl: true) do |http|
        http.request(req)
    end
    
    res_data = JSON.parse(res.body)
    case res.code.to_i
    when 200
        data = res_data['data']
        # Store data in global variables
        $box_id = data['id'] #first level no dig needed
        $box_type = data.dig('atttributes', 'type') #dig for nested values
        $box_name = data.dig('atttributes', 'name')
        $box_desc = data.dig('atttributes', 'description')
        $box_barcode = data.dig('atttributes', 'barcode_tag')
        # Relationships
        $box_type_id = data.dig('relationships', 'box_type', 'data', 'id')
        $box_container_id = data.dig('relationships', 'container', 'id')
        # Arrays
        $box_vials_id = data.dig('relationships', 'vials', 'data')&.map { |v| v['id'] } || []
        $box_udfs_id = data.dig('relationships', 'udfs', 'data')&.map { |u| u['id'] } || []
        puts "Successfully retreived box: #{$box_name} (ID: #{$box_id})"
        return {success: true, data: data }
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

  def create_box(name: nil, desc: nil, box_type_id: nil, box_container_id: nil)
    method = '/api/v2/boxes/'
    url = URI.join($current_server, method)
    
    # Build request body according to API spec
    box_params = {}
    box_params['name'] = name unless name.nil || name.strip.empty?
    box_params['desc'] = desc unless desc.nil || desc.strip.empty?
    box_params['box_type_id'] = box_type_id.to_i unless box_type_id.nil || box_type_id.strip.empty?
    box_params['box_container_id'] = box_container_id.to_i unless box_container_id.nil || box_container_id.strip.empty?
    
    #Check if there are any params to send
    if box_params.empty?
        puts "No parameters provided for box creation"
        return { success: false, error: "No parameters given"}
    end
    # Wrap values in key as per API spec
    request_body = { 'box' => box_params }
    req = Net::HTTP::Post.new(url)
    req['Authorization'] = $token
    req['Accept'] = 'application/json'
    req['Content-Type'] = 'application/json'
    req.body =request_body.to_json
    res = Net::HTTP.start(url.hostname, url.port, use_ssl: true) do |http|
        http.request(req)
    end

    res_data = JSON.parse(res.body)
    case res.code.to_i
    when 201
      data = res_data['data']
      #Update global variables with data
      $box_id = data['id'] #first level no dig needed
      $box_type = data.dig('atttributes', 'type') #dig for nested values
      $box_name = data.dig('attributes', 'name')
      $box_desc = data.dig('attributes', 'description')
      $box_barcode = data.dig('attributes', 'barcode_tag')
      #Extract relationships
      $box_type_id = data.dig('relationships', 'box_type', 'data', 'id')
      $box_container_id = data.dig('relationships', 'container', 'id')
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

  def update_box(uid, new_name, new_desc, new_barcode_tag)
    method = '/api/v2/boxes/'
    url = URI.join($current_server, method, uid)
    params = { 'box': { 'name': new_name, 'description': new_desc, 'barcode_tag': new_barcode_tag}}
    req = Net::HTTP::Patch.new(url)
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
      #Update global variables with data
      $box_id = res_data['id']#first level no dig needed
      $box_type = data.dig('atttributes', 'type') #dig for nested values
      $box_name = data.dig('attributes', 'name')
      $box_desc = data.dig('attributes', 'description')
      $box_barcode = data.dig('attributes', 'barcode_tag')
      # Extract relationships
      $box_type_id = data.dig('relationships', 'box_type', 'data', 'id')
      $box_container_id = data.dig('relationships', 'container', 'id')
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

  def list_boxes(filters: nil)
    method = 'api/v2/boxes'
    url = URI.join($current_server, method)
    # Add filter params
    if filters && !filters.empty?
      query_params = filters.map { |k, v| "filters[#{k}]=#{URI.encode_www_form_component(v)}"}.join('&')
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
      data = res_data['data']
      #Update global variables with data
      $box_id = res_data['id']#first level no dig needed
      $box_type = data.dig('atttributes', 'type') #dig for nested values
      $box_name = data.dig('attributes', 'name')
      $box_desc = data.dig('attributes', 'description')
      $box_barcode = data.dig('attributes', 'barcode_tag')
      puts "Retrieved #{data.length} box(es)"
      return { success: true, data: data, count: boxes.length}
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

  # Convenience methods:
  # @param box_id [Integer] Box ID
  # @return [Hash] Response hash with :success, :data/:errro
    def get_box(box_id)
      list_boxes(filters: { 'box_id_eq' => box_id})
    end
    
  # @param  barcode [String, Integer] Box barcode
  # @return [Hash] Response hash with :success, :data/:errro
    def find_box_barcode(barcode)
      list_boxes(filters: { 'barcode_eq' => barcode.to_s})
    end

    # @param vial_barcode [Integer] Vial barcode
    # @return [Hash] Response hash with :success, :data/:error
    def get_box_by_vial_barcode(vial_barcode)
      list_boxes(filters: { 'vial_barcode_eq' => vial_barcode})
    end
end

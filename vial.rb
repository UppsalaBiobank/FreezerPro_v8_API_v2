# Vials functions - FreezerPro API V2

module Vial
  extend self

  # Retrieve a specific vial by ID
  # @param uid [String, Integer] Vial ID
  # @return [Hash] Response hash with :success, :data/:error
  def retrieve_vial(uid)
    method = '/api/v2/vials/'
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
      $vial_id = data['id']
      $vial_custom_id = data.dig('attributes', 'custom_id')
      $vial_barcode = data.dig('attributes', 'barcode_tag')
      $vial_rfid = data.dig('attributes', 'rfid_tag')
      $vial_position = data.dig('attributes', 'position')
      $vial_freeze_thaw = data.dig('attributes', 'freeze_thaw')
      $vial_out_by_user_id = data.dig('attributes', 'out_by_user_id')
      $vial_out_at = data.dig('attributes', 'out_at')
      $vial_sample_id = data.dig('attributes', 'sample_id')
      $vial_volume = data.dig('attributes', 'volume')
      $vial_name = data.dig('attributes', 'name')
      $vial_created_at = data.dig('attributes', 'created_at')
      $vial_updated_at = data.dig('attributes', 'updated_at')
      
      # Extract relationships
      $vial_sample_relationship_id = data.dig('relationships', 'sample', 'data', 'id')
      $vial_box_id = data.dig('relationships', 'box', 'data', 'id')
      
      puts "Successfully retrieved vial: #{$vial_name || $vial_barcode} (ID: #{$vial_id})"
      puts "  Sample ID: #{$vial_sample_id}, Box ID: #{$vial_box_id}, Position: #{$vial_position}"
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

  # Update a specific vial
  # @param uid [String, Integer] Vial ID
  # @param box_id [Integer, nil] New box ID
  # @param position [Integer, nil] New position in box
  # @param volume [Float, nil] New volume
  # @param barcode_tag [String, nil] New barcode tag
  # @param rfid_tag [String, nil] New RFID tag
  # @return [Hash] Response hash with :success, :data/:error
  def update_vial(uid, box_id: nil, position: nil, volume: nil, barcode_tag: nil, rfid_tag: nil)
    method = '/api/v2/vials/'
    url = URI.join($current_server, method, uid.to_s)
    
    # Build the request body according to API spec
    vial_params = {}
    vial_params['box_id'] = box_id.to_i unless box_id.nil?
    vial_params['position'] = position.to_i unless position.nil?
    vial_params['volume'] = volume.to_f unless volume.nil?
    vial_params['barcode_tag'] = barcode_tag unless barcode_tag.nil? || barcode_tag.strip.empty?
    vial_params['rfid_tag'] = rfid_tag unless rfid_tag.nil? || rfid_tag.strip.empty?
    
    # Check if we have any params to send
    if vial_params.empty?
      puts "No parameters provided for update"
      return { success: false, error: "No parameters provided" }
    end
    
    # Wrap in 'vial' key as per API spec
    request_body = { 'vial' => vial_params }
    
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
      $vial_id = data['id']
      $vial_custom_id = data.dig('attributes', 'custom_id')
      $vial_barcode = data.dig('attributes', 'barcode_tag')
      $vial_rfid = data.dig('attributes', 'rfid_tag')
      $vial_position = data.dig('attributes', 'position')
      $vial_freeze_thaw = data.dig('attributes', 'freeze_thaw')
      $vial_out_by_user_id = data.dig('attributes', 'out_by_user_id')
      $vial_out_at = data.dig('attributes', 'out_at')
      $vial_sample_id = data.dig('attributes', 'sample_id')
      $vial_volume = data.dig('attributes', 'volume')
      $vial_name = data.dig('attributes', 'name')
      $vial_created_at = data.dig('attributes', 'created_at')
      $vial_updated_at = data.dig('attributes', 'updated_at')
      
      # Extract relationships
      $vial_sample_relationship_id = data.dig('relationships', 'sample', 'data', 'id')
      $vial_box_id = data.dig('relationships', 'box', 'data', 'id')
      
      puts "Successfully updated vial (ID: #{$vial_id})"
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

  # Creates a new vial
  # @param sample_id [Integer] Sample ID (required)
  # @param box_id [Integer] Box ID (required)
  # @param position [Integer] Position in box (required)
  # @param volume [Float, nil] Volume (optional)
  # @return [Hash] Response hash with :success, :data/:error
  def create_vial(sample_id:, box_id:, position:, volume: nil)
    method = '/api/v2/vials'
    url = URI.join($current_server, method)

    # Build the request body according to API spec
    vial_params = {}
    vial_params['sample_id'] = sample_id.to_i
    vial_params['box_id'] = box_id.to_i
    vial_params['position'] = position.to_i
    vial_params['volume'] = volume.to_f unless volume.nil?

    # Check if we have any params to send
    if vial_params.empty?
      puts "No parameters provided for update"
      return { success: false, error: "No parameters provided" }
    end
    
    # Wrap in 'vial' key as per API spec
    request_body = { 'vial' => vial_params }

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
      vial_id = data['id']
      vial_name = data.dig('attributes', 'name')
      vial_barcode = data.dig('attributes', 'barcode_tag')
      puts "Successfully created vial: #{vial_name || vial_barcode} (ID: #{vial_id})"
      return { success: true, data: data, id: vial_id }
      
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

  # Delete a vial
  # @param uid [String, Integer] Vial ID
  # @return [Hash] Response hash with :success, :error
  def delete_vial(uid)
    method = '/api/v2/vials/'
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
      puts "Successfully deleted vial (ID: #{uid})"
      return { success: true }
      
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

  # Get all vials with optional filtering
  # Supports extensive filtering - see documentation for full list
  # @param filters [Hash, nil] Hash of filter parameters
  # @return [Hash] Response hash with :success, :data/:error
  #
  # @example Filter by barcode
  #   list_vials(filters: { 'barcode_eq' => '1000016' })
  #
  # @example Filter by sample name
  #   list_vials(filters: { 'sample_name_eq' => 'AdvSearchSample' })
  #
  # @example Filter by box and sample
  #   list_vials(filters: { 'box_name_eq' => 'Box 1', 'sample_name_eq' => 'Sample A' })
  #
  # @example Filter by volume
  #   list_vials(filters: { 'volume_lt' => '99' })
  #
  # @example Filter vials out of freezer
  #   list_vials(filters: { 'out_of_freezer_eq' => 'true' })
  def list_vials(filters: nil)
    method = '/api/v2/vials'
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
      vials = res_data['data']
      puts "Retrieved #{vials.length} vial(s)"
      return { success: true, data: vials, count: vials.length }
      
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

## Convenience methods:
  # Get all vials for a specific sample
  # @param sample_id [String, Integer] Sample ID
  # @return [Hash] Response hash with :success, :data/:error
  def get_sample_vials(sample_id)
    list_vials(filters: { 'sample_id_eq' => sample_id.to_s })
  end

  # Get all vials in a specific box
  # @param box_id [String, Integer] Box ID
  # @return [Hash] Response hash with :success, :data/:error
  def get_box_vials(box_id)
    list_vials(filters: { 'box_id_eq' => box_id.to_s })
  end

  # Find vial by barcode
  # @param barcode [String] Barcode tag
  # @return [Hash] Response hash with :success, :data/:error
  def find_by_barcode(barcode)
    list_vials(filters: { 'barcode_eq' => barcode.to_s })
  end
  
  # Find vials out of freezer
  # @return [Hash] Response hash with :success, :data/:error
  def get_vials_out_of_freezer
    list_vials(filters: { 'out_of_freezer_eq' => 'true' })
  end

  # Move vial to new location
  # @param uid [String, Integer] Vial ID
  # @param new_box_id [Integer] New box ID
  # @param new_position [Integer] New position in box
  # @return [Hash] Response hash with :success, :data/:error
  def move_vial(uid, new_box_id, new_position)
    update_vial(uid, box_id: new_box_id, position: new_position)
  end
end

# Audit Records functions - FreezerPro API V2

module AuditRecord
  extend self

  # Retrieve a specific audit record by ID
  # @param uid [String, Integer] Audit Record ID
  # @return [Hash] Response hash with :success, :data/:error
  def retrieve_audit_record(uid)
    method = '/api/v2/audit_records/'
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
      $audit_record_id = data['id'] #first level no dig needed
      $audit_record_message = data.dig('attributes', 'message') #dig for nested vaules
      $audit_record_comment = data.dig('attributes', 'comment')
      $audit_record_created_at = data.dig('attributes', 'created_at')
      $audit_record_user = data.dig('attributes', 'user')
      
      puts "Successfully retrieved audit record (ID: #{$audit_record_id})"
      puts "Message: #{$audit_record_message}"
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

  # Get all audit records with optional filtering
  # Supports filtering by: comment, creation_date, obj_id, obj_type
  # Operators: eq (equals), neq (not equals), cont (contains), gt (greater than), lt (less than)
  # 
  # @param filters [Hash, nil] Hash of filter parameters
  # @return [Hash] Response hash with :success, :data/:error
  #
  # @example Filter by object type and ID
  #   list_audit_records(filters: { 'obj_type_eq' => 'User', 'obj_id_eq' => '41' })
  #
  # @example Filter by date
  #   list_audit_records(filters: { 'creation_date_gt' => '06/23/2022' })
  #
  # @example Filter by comment content
  #   list_audit_records(filters: { 'comment_cont' => 'moved' })
  def list_audit_records(filters: nil)
    method = '/api/v2/audit_records'
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
      data = res_data['data']
      # Store data in global variables
      $audit_record_id = data['id'] #first level no dig needed
      $audit_record_message = data.dig('attributes', 'message') #dig for nested vaules
      $audit_record_comment = data.dig('attributes', 'comment')
      $audit_record_created_at = data.dig('attributes', 'created_at')
      $audit_record_user = data.dig('attributes', 'user')
      puts "Retrieved #{data.length} audit record(s)"
      return { success: true, data: data, count: data.length }
      
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

  # Get audit records for a specific object
  # @param obj_type [String] Type of object (e.g., 'User', 'Sample', 'Vial', 'Box')
  # @param obj_id [String, Integer] ID of the object
  # @return [Hash] Response hash with :success, :data/:error
  def get_object_audit_history(obj_type, obj_id)
    list_audit_records(filters: { 
      'obj_type_eq' => obj_type, 
      'obj_id_eq' => obj_id.to_s 
    })
  end

  # Get recent audit records (created after a specific date)
  # @param date [String] Date in format MM/DD/YYYY
  # @return [Hash] Response hash with :success, :data/:error
  def get_recent_audit_records(date)
    list_audit_records(filters: { 'creation_date_gt' => date })
  end

  # Get audit records by user
  # @param username [String] Username to filter by
  # @return [Hash] Response hash with :success, :data/:error
  def get_user_audit_records(username)
    list_audit_records(filters: { 'user_eq' => username })
  end

  # Search audit records by comment content
  # @param search_term [String] Term to search for in comments
  # @return [Hash] Response hash with :success, :data/:error
  def search_audit_comments(search_term)
    list_audit_records(filters: { 'comment_cont' => search_term })
  end

  # Display audit records in a readable format
  # @param records [Array] Array of audit record data
  def display_audit_records(records)
    return puts "No audit records to display" if records.nil? || records.empty?
    
    puts "\n" + "=" * 80
    puts "AUDIT RECORDS (#{records.length} total)"
    puts "=" * 80
    
    records.each_with_index do |record, index|
      attrs = record['attributes']
      puts "\n[#{index + 1}] ID: #{record['id']}"
      puts "    Date: #{attrs['created_at']}"
      puts "    User: #{attrs['user'] || 'N/A'}"
      puts "    Message: #{attrs['message']}"
      puts "    Comment: #{attrs['comment']}" if attrs['comment'] && !attrs['comment'].empty?
      puts "-" * 80
    end
  end
end

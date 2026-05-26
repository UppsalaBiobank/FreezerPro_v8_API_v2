module API
  extend self

  # Generic single-record retrieve function.
  # Used as boilerplate for all module-specific Retrieve methods.
  # @param uid [String, Integer] ID of the record to retrieve
  # @param endpoint [String] API endpoint name e.g. 'containers', 'freezers'
  # @param verbose [Boolean] Whether to print status messages
  # @return [Hash] Response hash with :success, :data, :count, or :error
  def retreive(uid, endpoint:, verbose: true)
    method = "/api/v2/#{endpoint}/"
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
      puts "Retrieved #{endpoint}: #{uid}" if verbose
      return { success: true, data: data, count: 1 }  # single record by uid, always count: 1
    when 400..404
      error_msg  = res_data.dig('errors', 0, 'detail') || 'Unknown error'  # fallback if detail is missing
      error_code = res_data.dig('errors', 0, 'status') || res.code         # use HTTP status if not in response
      puts "Code: #{error_code}: #{error_msg}"
      return { success: false, error: error_msg, code: error_code }
    else
      puts "Unexpected error: #{res.code} - #{res.body}"                   # response is outside expected range
      return { success: false, error: res.body, code: res.code }
    end
 
  rescue StandardError => e
    puts "Request failed: #{e.message}"
    return { success: false, error: e.message }
  end

  # Generic filtered search function.
  # Used as boilerplate for all module-specific Get methods.
  # @param uid [String, Integer] ID of the record to retrieve
  # @param endpoint [String] API endpoint name e.g. 'containers', 'freezers'
  # @param verbose [Boolean] Whether to print status messages
  # @return [Hash] Response hash with :success, :data, :count, or :error
  def list(endpoint:, filters: nil, verbose: true)
    method = "/api/v2/#{endpoint}"
    url = URI.join($current_server, method)

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
      puts "Retrieved #{data.length} #{endpoint}" if verbose
      return { success: true, data: data, count: data.length }
    when 400..404
      error_msg  = res_data.dig('errors', 0, 'detail') || 'Unknown error'
      error_code = res_data.dig('errors', 0, 'status') || res.code
      puts "Code: #{error_code}: #{error_msg}" if verbose
      return { success: false, error: error_msg, code: error_code }
    else
      puts "Unexpected error: #{res.code} - #{res.body}" if verbose
      return { success: false, error: res.body, code: res.code }
    end

  rescue StandardError => e
    puts "Request failed: #{e.message}"
    return { success: false, error: e.message }
  end

  #Delete single post
  #USed as boilerplate for all module specific Delete methods
  # @param uid [String, Integer] ID of the records to delete
  # @param endpoint [String] API enpoint name e.g 'freeezers', 'vials'
  # @param verbose [Boolean] Whether to print status message
  # @return [Hash] Response hash with :success, :data, :count, or :error
  def delete(uid, endpoint:, verbose: true)
    method = "/api/v2/#{endpoint}/"
    url = URI.join($current_server, method, uid.to_s)
    req = Net::HTTP::Delete.new(url)
    req['Authorization'] = $token
    req['Accept'] = '*/*'
    
    res = Net::HTTP.start(url.hostname, url.port, use_ssl: true) do |http|
      http.request(req)
    end


    case res.code.to_i
    when 204 #no content - successful deletion
      return { success: true }
      puts "Deleted #{endpoint}: #{uid}" if verbose
    when 200 #if api returns a response here.
      return { success: true}
      puts "Deleted #{endpoint}: #{uid}" if verbose
    when 400..404
      res_data = res_body.empty? ? {} : JSON.parse(res_body)
      error_msg  = res_data.dig('errors', 0, 'detail') || 'Unknown error'
      error_code = res_data.dig('errors', 0, 'status') || res.code
      puts "Code: #{error_code}: #{error_msg}" if verbose
      return { success: false, error: error_msg, code: error_code }
    else
      puts "Unexpected error: #{res.code} - #{res.body}" if verbose
      return { success: false, error: res.body, code: res.code }
    end

  rescue StandardError => e
    puts "Request failed: #{e.message}"
    return { success: false, error: e.message }
  end
  
end

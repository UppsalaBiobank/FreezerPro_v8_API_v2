##WIP
# Display Helpers - Reusable display functions for FreezerPro API responses

module DisplayHelpers
  extend self

  # Display vials in a formatted table
  # @param result [Hash] Result hash from Vial methods
  # @param title [String] Title to display
  def display_vials(result, title: "VIALS")
    return display_error(result) unless result[:success]
    
    puts "\n" + "=" * 80
    puts "#{title} (#{result[:count]} total)"
    puts "=" * 80
    
    if result[:count] == 0
      puts "No vials found."
      return
    end
    
    result[:data].each_with_index do |vial, index|
      attrs = vial['attributes']
      box_id = vial.dig('relationships', 'box', 'data', 'id')
      sample_id = vial.dig('relationships', 'sample', 'data', 'id')
      puts "\n[#{index + 1}] Vial ID: #{vial['id']}"
      puts "    Name: #{attrs['name']}"
      puts "    Barcode: #{attrs['barcode_tag']}"
      #puts "    RFID: #{attrs['rfid_tag']}" if attrs['rfid_tag']
      puts "    Position: #{attrs['position']}"
      puts "    Volume: #{attrs['volume']}"
      puts "    Sample ID: #{sample_id}"
      puts "    Box ID: #{box_id}"
      #puts "    Created: #{attrs['created_at']}"
      #puts "    Updated: #{attrs['updated_at']}"
      #puts "    Freeze/Thaw Cycles: #{attrs['freeze_thaw']}" if attrs['freeze_thaw']
     
      #if attrs['out_at']
      #  puts "    ⚠️  OUT OF FREEZER"
      #  puts "    Taken out: #{attrs['out_at']}"
      #  puts "    Taken by: User #{attrs['out_by_user_id']}" if attrs['out_by_user_id']
      #end
      puts "-" * 80
    end
  end

  # Display samples in a formatted table
  # @param result [Hash] Result hash from Sample methods
  # @param title [String] Title to display
  def display_samples(result, title: "SAMPLES")
    return display_error(result) unless result[:success]
    
    puts "\n" + "=" * 80
    puts "#{title} (#{result[:count]} total)"
    puts "=" * 80
    
    if result[:count] == 0
      puts "No samples found."
      return
    end
    
    result[:data].each_with_index do |sample, index|
      attrs = sample['attributes']
      sample_type_id = sample.dig('relationships', 'sample_type', 'data', 'id')
      sample_source_id = sample.dig('relationships', 'sample_source', 'data', 'id')
      vials = sample.dig('relationships', 'vials', 'data') || []
      
      puts "\n[#{index + 1}] Sample ID: #{sample['id']}"
      puts "    Name: #{attrs['name']}"
      puts "    Description: #{attrs['description']}"
      puts "    Type ID: #{sample_type_id}"
      puts "    Source ID: #{sample_source_id}"
      puts "    Number of Vials: #{vials.length}"
      puts "    Created: #{attrs['created_at']}"
      puts "    Updated: #{attrs['updated_at']}"
      puts "-" * 80
    end
  end

  # Display sample sources in a formatted table
  # @param result [Hash] Result hash from SampleSource methods
  # @param title [String] Title to display
  def display_sample_sources(result, title: "SAMPLE SOURCES")
    return display_error(result) unless result[:success]
    
    puts "\n" + "=" * 80
    puts "#{title} (#{result[:count]} total)"
    puts "=" * 80
    
    if result[:count] == 0
      puts "No sample sources found."
      return
    end
    
    result[:data].each_with_index do |source, index|
      attrs = source['attributes']
      type_id = source.dig('relationships', 'sample_source_type', 'data', 'id')
      samples = source.dig('relationships', 'samples', 'data') || []
      
      puts "\n[#{index + 1}] Sample Source ID: #{source['id']}"
      puts "    Name: #{attrs['name']}"
      puts "    Description: #{attrs['description']}"
      puts "    Type ID: #{type_id}"
      puts "    Enabled: #{attrs['enabled']}"
      puts "    Number of Samples: #{samples.length}"
      puts "    Created: #{attrs['created_at']}"
      puts "    Updated: #{attrs['updated_at']}"
      puts "-" * 80
    end
  end

  # Display audit records in a formatted table
  # @param result [Hash] Result hash from AuditRecord methods
  # @param title [String] Title to display
  def display_audit_records(result, title: "AUDIT RECORDS")
    return display_error(result) unless result[:success]
    
    puts "\n" + "=" * 80
    puts "#{title} (#{result[:count]} total)"
    puts "=" * 80
    
    if result[:count] == 0
      puts "No audit records found."
      return
    end
    
    result[:data].each_with_index do |record, index|
      attrs = record['attributes']
      puts "\n[#{index + 1}] ID: #{record['id']}"
      puts "    Date: #{attrs['created_at']}"
      puts "    User: #{attrs['user'] || 'N/A'}"
      puts "    Message: #{attrs['message']}"
      puts "    Comment: #{attrs['comment']}" if attrs['comment'] && !attrs['comment'].empty?
      puts "-" * 80
    end
  end

  # Display a single entity (any type)
  # @param result [Hash] Result hash from any retrieve method
  # @param title [String] Title to display
  def display_single(result, title: "DETAILS")
    return display_error(result) unless result[:success]
    
    data = result[:data]
    attrs = data['attributes']
    
    puts "\n" + "=" * 80
    puts title
    puts "=" * 80
    
    puts "\nID: #{data['id']}"
    puts "Type: #{data['type']}"
    
    puts "\nAttributes:"
    attrs.each do |key, value|
      puts "  #{key}: #{value}"
    end
    
    if data['relationships']
      puts "\nRelationships:"
      data['relationships'].each do |rel_name, rel_data|
        if rel_data['data'].is_a?(Array)
          ids = rel_data['data'].map { |r| r['id'] }
          puts "  #{rel_name}: [#{ids.join(', ')}]"
        elsif rel_data['data']
          puts "  #{rel_name}: #{rel_data['data']['id']}"
        else
          puts "  #{rel_name}: null"
        end
      end
    end
    
    puts "=" * 80
  end

  # Display error message
  # @param result [Hash] Result hash with error
  def display_error(result)
    puts "\n❌ ERROR"
    puts "=" * 80
    puts "Code: #{result[:code]}" if result[:code]
    puts "Message: #{result[:error]}"
    puts "=" * 80
  end

  # Export results to CSV format
  # @param result [Hash] Result hash from list methods
  # @param fields [Array] Array of field names to include
  # @param filename [String] Output filename
  def export_to_csv(result, fields:, filename: 'export.csv')
    return display_error(result) unless result[:success]
    
    File.open(filename, 'w') do |file|
      # Write header
      file.puts fields.join(',')
      
      # Write data rows
      result[:data].each do |item|
        values = fields.map do |field|
          if field.include?('.')
            # Handle nested fields like 'attributes.name'
            parts = field.split('.')
            value = item
            parts.each { |part| value = value&.dig(part) }
            value
          else
            item.dig('attributes', field)
          end
        end
        file.puts values.map { |v| "\"#{v}\"" }.join(',')
      end
    end
    
    puts "✅ Exported #{result[:count]} records to #{filename}"
  end

  # Display summary statistics
  # @param result [Hash] Result hash from list methods
  def display_summary(result)
    return display_error(result) unless result[:success]
    
    puts "\n" + "=" * 80
    puts "SUMMARY STATISTICS"
    puts "=" * 80
    puts "Total Records: #{result[:count]}"
    
    if result[:count] > 0
      # Try to calculate some basic stats if data is available
      first_item = result[:data].first
      attrs = first_item['attributes']
      
      puts "\nAvailable Fields:"
      attrs.keys.each { |key| puts "  - #{key}" }
      
      # If there's a numeric field like 'volume', calculate stats
      if attrs['volume']
        volumes = result[:data].map { |item| item.dig('attributes', 'volume') }.compact
        if volumes.any?
          puts "\nVolume Statistics:"
          puts "  Min: #{volumes.min}"
          puts "  Max: #{volumes.max}"
          puts "  Average: #{(volumes.sum.to_f / volumes.length).round(2)}"
        end
      end
    end
    
    puts "=" * 80
  end

  # Display as simple list (one line per item)
  # @param result [Hash] Result hash from list methods
  # @param fields [Array] Fields to display per line
  def display_list(result, fields: ['id', 'name'])
    return display_error(result) unless result[:success]
    
    puts "\n#{result[:count]} result(s):"
    result[:data].each do |item|
      line_parts = fields.map do |field|
        value = item.dig('attributes', field) || item[field]
        "#{field}: #{value}"
      end
      puts "  • #{line_parts.join(' | ')}"
    end
  end

  # Interactive menu to display item details
  # @param result [Hash] Result hash from list methods
  def interactive_select(result)
    return display_error(result) unless result[:success]
    
    if result[:count] == 0
      puts "No items to select from."
      return nil
    end
    
    # Display numbered list
    puts "\nSelect an item:"
    result[:data].each_with_index do |item, index|
      name = item.dig('attributes', 'name') || item.dig('attributes', 'message') || 'N/A'
      puts "  #{index + 1}. #{name} (ID: #{item['id']})"
    end
    
    print "\nEnter number (or 0 to cancel): "
    choice = gets.chomp.to_i
    
    if choice > 0 && choice <= result[:count]
      selected = result[:data][choice - 1]
      display_single({ success: true, data: selected }, title: "SELECTED ITEM")
      return selected
    else
      puts "Selection cancelled."
      return nil
    end
  end
end

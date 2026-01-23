# Skapa en CSV fil e.g UBB-xxxx.csv
# barcode
# 123456
# 789123
# 456789

# i main.rb
# BatchVialOperations.batch_delete_from_csv
# (
#   input_csv: 'barcodes.csv',
#   output_csv: 'deletion_results.csv'
# )
# 
# Alt2.
# Vial barcode,kolumn2
# 123456,data
# 789123,merdata
# 456789,ytterligaredata

# Där anges kolumn-namn som innehåller barcode e.g "Vial Barcode":
# BatchVialOperations.batch_delete_from_csv(
#   input_csv: 'barcodes.csv',
#   output_csv: 'deletion_results.csv',
#   barcode_column: 'Vial Barcode'
# )

# Alt3.
# Radering utan CSV
# barcodes = ['1000016', '1000017', '1000018']
# BatchVialOperations.batch_delete_from_array(
#   barcodes: barcodes,
#   output_csv: 'deletion_results.csv'

####################################################################################
# Code start
# Batch Vial Deletion from CSV
# Reads barcodes from CSV, finds vials, deletes them, and generates results report

require 'csv'

module BatchVialOperations
  extend self

  # Delete vials from CSV file containing barcodes
  # @param input_csv [String] Path to input CSV file with barcodes
  # @param output_csv [String] Path to output results CSV file
  # @param barcode_column [String, Integer] Column name or index containing barcodes (default: 0)
  # @return [Hash] Summary of operation
  def batch_delete_from_csv(input_csv:, output_csv: 'deletion_results.csv', barcode_column: 0)
    unless File.exist?(input_csv)
      puts "❌ Error: Input file '#{input_csv}' not found"
      return { success: false, error: "File not found" }
    end

    results = []
    success_count = 0
    fail_count = 0

    puts "\n" + "=" * 80
    puts "BATCH VIAL DELETION"
    puts "=" * 80
    puts "Input file: #{input_csv}"
    puts "Output file: #{output_csv}"
    puts "\nProcessing vials...\n"

    # Read input CSV
    CSV.foreach(input_csv, headers: true) do |row|
      barcode = if barcode_column.is_a?(Integer)
                  row[barcode_column]
                elsif barcode_column.is_a?(String)
                  row[barcode_column]
                else
                  row[0]
                end

      # Skip empty rows
      next if barcode.nil? || barcode.strip.empty?

      barcode = barcode.strip
      print "Processing barcode: #{barcode}... "

      result = process_single_vial(barcode)
      results << result

      if result[:status].start_with?('Success')
        success_count += 1
        puts "✅ #{result[:status]}"
      else
        fail_count += 1
        puts "❌ #{result[:status]}"
      end
    end

    # Write results to CSV
    write_results_csv(results, output_csv)

    # Display summary
    puts "\n" + "=" * 80
    puts "SUMMARY"
    puts "=" * 80
    puts "Total processed: #{results.length}"
    puts "✅ Successful deletions: #{success_count}"
    puts "❌ Failed operations: #{fail_count}"
    puts "\nResults saved to: #{output_csv}"
    puts "=" * 80

    {
      success: true,
      total: results.length,
      successful: success_count,
      failed: fail_count,
      results: results
    }
  rescue StandardError => e
    puts "\n❌ Error during batch processing: #{e.message}"
    puts e.backtrace.first(5)
    { success: false, error: e.message }
  end

  # Process a single vial: find, store data, and delete
  # @param barcode [String] Vial barcode
  # @return [Hash] Result data for this vial
  def process_single_vial(barcode)
    result_data = {
      barcode: barcode,
      sample_id: '',
      box_id: '',
      position: '',
      volume: '',
      status: ''
    }

    # Step 1: Find vial by barcode
    search_result = Vial.find_by_barcode(barcode)

    unless search_result[:success]
      result_data[:status] = "F: API Error - #{search_result[:error]}"
      return result_data
    end

    if search_result[:count] == 0
      result_data[:status] = "F: No vial found"
      return result_data
    end

    # Step 2: Extract vial data
    vial = search_result[:data].first
    vial_id = vial['id']
    attrs = vial['attributes']
    
    result_data[:sample_id] = attrs['sample_id'].to_s
    result_data[:box_id] = vial.dig('relationships', 'box', 'data', 'id').to_s
    result_data[:position] = attrs['position'].to_s
    result_data[:volume] = attrs['volume'].to_s

    # Step 3: Delete the vial
    delete_result = Vial.delete_vial(vial_id)

    if delete_result[:success]
      result_data[:status] = "Success"
    else
      result_data[:status] = "F: Not deleted - #{delete_result[:error]}"
    end

    result_data
  rescue StandardError => e
    result_data[:status] = "F: Exception - #{e.message}"
    result_data
  end

  # Write results to CSV file
  # @param results [Array] Array of result hashes
  # @param output_file [String] Output CSV filename
  def write_results_csv(results, output_file)
    CSV.open(output_file, 'w') do |csv|
      # Write header
      csv << ['Vial barcode', 'Sample ID', 'Box ID', 'Position', 'Volume', 'Status']

      # Write data rows
      results.each do |result|
        csv << [
          result[:barcode],
          result[:sample_id],
          result[:box_id],
          result[:position],
          result[:volume],
          result[:status]
        ]
      end
    end
  end

  # Alternative: Delete vials from array of barcodes (no CSV input needed)
  # @param barcodes [Array] Array of barcode strings
  # @param output_csv [String] Path to output results CSV file
  # @return [Hash] Summary of operation
  def batch_delete_from_array(barcodes:, output_csv: 'deletion_results.csv')
    results = []
    success_count = 0
    fail_count = 0

    puts "\n" + "=" * 80
    puts "BATCH VIAL DELETION"
    puts "=" * 80
    puts "Total barcodes: #{barcodes.length}"
    puts "Output file: #{output_csv}"
    puts "\nProcessing vials...\n"

    barcodes.each do |barcode|
      next if barcode.nil? || barcode.strip.empty?

      barcode = barcode.strip
      print "Processing barcode: #{barcode}... "

      result = process_single_vial(barcode)
      results << result

      if result[:status].start_with?('Success')
        success_count += 1
        puts "✅ #{result[:status]}"
      else
        fail_count += 1
        puts "❌ #{result[:status]}"
      end
    end

    # Write results to CSV
    write_results_csv(results, output_csv)

    # Display summary
    puts "\n" + "=" * 80
    puts "SUMMARY"
    puts "=" * 80
    puts "Total processed: #{results.length}"
    puts "✅ Successful deletions: #{success_count}"
    puts "❌ Failed operations: #{fail_count}"
    puts "\nResults saved to: #{output_csv}"
    puts "=" * 80

    {
      success: true,
      total: results.length,
      successful: success_count,
      failed: fail_count,
      results: results
    }
  rescue StandardError => e
    puts "\n❌ Error during batch processing: #{e.message}"
    { success: false, error: e.message }
  end

  # Dry run: Find vials but don't delete (for testing)
  # @param input_csv [String] Path to input CSV file with barcodes
  # @param output_csv [String] Path to output results CSV file
  # @param barcode_column [String, Integer] Column name or index containing barcodes
  # @return [Hash] Summary of operation
  def dry_run_from_csv(input_csv:, output_csv: 'dry_run_results.csv', barcode_column: 0)
    unless File.exist?(input_csv)
      puts "❌ Error: Input file '#{input_csv}' not found"
      return { success: false, error: "File not found" }
    end

    results = []
    found_count = 0
    not_found_count = 0

    # Read input CSV
    puts "\n" + "=" * 80
    puts "DRY RUN - VIAL LOOKUP (NO DELETION)"
    puts "=" * 80
    puts "Input file: #{input_csv}"
    puts "Output file: #{output_csv}"
    puts "\nProcessing vials...\n"

    CSV.foreach(input_csv, headers: true) do |row|
      barcode = if barcode_column.is_a?(Integer)
                  row[barcode_column]
                elsif barcode_column.is_a?(String)
                  row[barcode_column]
                else
                  row[0]
                end
      
      # Skip empty rows
      next if barcode.nil? || barcode.strip.empty?

      barcode = barcode.strip
      print "Checking barcode: #{barcode}... "

      result_data = {
        barcode: barcode,
        sample_id: '',
        box_id: '',
        position: '',
        volume: '',
        status: ''
      }

      search_result = Vial.find_by_barcode(barcode)

      if search_result[:success] && search_result[:count] > 0
        vial = search_result[:data].first
        attrs = vial['attributes']
        
        result_data[:sample_id] = attrs['sample_id'].to_s
        result_data[:box_id] = vial.dig('relationships', 'box', 'data', 'id').to_s
        result_data[:position] = attrs['position'].to_s
        result_data[:volume] = attrs['volume'].to_s
        result_data[:status] = "Found (would delete)"
        
        found_count += 1
        puts "✅ Found"
      else
        result_data[:status] = "Not found"
        not_found_count += 1
        puts "❌ Not found"
      end

      results << result_data
    end

    # Write results
    write_results_csv(results, output_csv)

    puts "\n" + "=" * 80
    puts "DRY RUN SUMMARY"
    puts "=" * 80
    puts "Total checked: #{results.length}"
    puts "✅ Found: #{found_count}"
    puts "❌ Not found: #{not_found_count}"
    puts "\nResults saved to: #{output_csv}"
    puts "⚠️  NOTE: This was a dry run. No vials were deleted."
    puts "=" * 80

    {
      success: true,
      total: results.length,
      found: found_count,
      not_found: not_found_count,
      results: results
    }
  rescue StandardError => e
    puts "\n Error during batch processing: #{e.message}"
    puts e.backtrace.first(5)
    { success: false, error: e.message }
  end

  def dry_run_from_csv(input_csv:, output_csv: 'dry_run_results.csv', barcode_column: 0)
    unless File.exist?(input_csv)
      puts "❌ Error: Input file '#{input_csv}' not found"
      return { success: false, error: "File not found" }
    end

    results = []
    found_count = 0
    not_found_count = 0

    # Read input CSV
    puts "\n" + "=" * 80
    puts "DRY RUN - VIAL LOOKUP (NO DELETION)"
    puts "=" * 80
    puts "Input file: #{input_csv}"
    puts "Output file: #{output_csv}"
    puts "\nProcessing vials...\n"

    CSV.foreach(input_csv, headers: true) do |row|
      barcode = if barcode_column.is_a?(Integer)
                  row[barcode_column]
                elsif barcode_column.is_a?(String)
                  row[barcode_column]
                else
                  row[0]
                end
      
      # Skip empty rows
      next if barcode.nil? || barcode.strip.empty?

      barcode = barcode.strip
      print "Checking barcode: #{barcode}... "

      result_data = {
        barcode: barcode,
        sample_id: '',
        box_id: '',
        position: '',
        volume: '',
        status: ''
      }

      search_result = Vial.find_by_barcode(barcode)

      if search_result[:success] && search_result[:count] > 0
        vial = search_result[:data].first
        attrs = vial['attributes']
        
        result_data[:sample_id] = attrs['sample_id'].to_s
        result_data[:box_id] = vial.dig('relationships', 'box', 'data', 'id').to_s
        result_data[:position] = attrs['position'].to_s
        result_data[:volume] = attrs['volume'].to_s
        result_data[:status] = "Found (would delete)"
        
        found_count += 1
        puts "✅ Found"
      else
        result_data[:status] = "Not found"
        not_found_count += 1
        puts "❌ Not found"
      end

      results << result_data
    end

    # Write results
    write_results_csv(results, output_csv)

    puts "\n" + "=" * 80
    puts "DRY RUN SUMMARY"
    puts "=" * 80
    puts "Total checked: #{results.length}"
    puts "✅ Found: #{found_count}"
    puts "❌ Not found: #{not_found_count}"
    puts "\nResults saved to: #{output_csv}"
    puts "⚠️  NOTE: This was a dry run. No vials were deleted."
    puts "=" * 80

    {
      success: true,
      total: results.length,
      found: found_count,
      not_found: not_found_count,
      results: results
    }
  rescue StandardError => e
    puts "\n Error during batch processing: #{e.message}"
    puts e.backtrace.first(5)
    { success: false, error: e.message }
  end
end

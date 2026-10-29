# this module will batch update vials i.e. do this in parallel 

require 'csv'
require 'parallel'

module UpdateVialParallel
  extend self

  # Update vials from csv file containing barcodes
  # @param input_csv [String] Path to input CSV file with barcodes
  # @param ouput_csv [String] Path to output results CSV file
  # @param barcode_column [String, Integer] Column containing barcodes (defult:0)
  # @return [Hash] Summary of operation
  def batch_update_w_barcode(
    input_csv:, 
    output_csv:,
    barcode_column: 0,
    name_column: 'Name', # whatever your CSV header is called
    volume_column: nil,
    position_column: nil,
    threads: 8) #threads: 10 can trigger rate limit during update phase
    
    unless File.exist?(input_csv)
      puts "Error: Input file '#{input_csv}' not found"
      return { success: false, error: "File not found" }
    end

    #Read all rows to array so update can be parallelized
    rows = []
    CSV.foreach(input_csv, headers: true, col_sep: ';') do |row|
      barcode = if barcode_column.is_a?(Integer) || barcode_column.is_a?(String)
                  row[barcode_column]
                else
                  row[0]
                end
      next if barcode.nil? || barcode.strip.empty?
      rows << row #store entire row not just barcode
    end

    puts "\n" + "=" * 80
    puts "BATCH VIAL UPDATE"
    puts "=" * 80
    puts "Input file: #{input_csv}"
    puts "Output file: #{output_csv}"
    puts "Threads: #{threads}"
    puts "\nProcessing #{rows.length} vials...\n"

    mutex = Mutex.new
    success_count = 0
    fail_count = 0

    results = Parallel.map(rows, in_threads: threads) do |row|
      barcode = row[barcode_column].to_s.strip

      #build payload from row - only include columns that are specified and have data
      #how it works if a column header differs from the string in the API and you dont want to edit the import.
      #'name' = API field, name_column = CSV column header
      field_map = 
      {
        #'volume' => volume_column,
        #'position' => position_column,
        'name' => name_column
      }

      payload = {}
      field_map.each do |api_field, column|
        next if column.nil? #skip if column is not specified
        value = row[column].to_s.strip
        next if value.empty? #skip i no data in column row
        payload[api_field] = value
      end

      # only send req if there is any data to update
      if payload.empty?
        next { barcode: barcode, status: 'Skipped: no data'} #still return a result row
      end

        sleep(rand(1.0..2.0)) #randomize delay to avoid synchronized bursts
        puts "Updating fields for barcode: #{barcode}... \n"

        result = process_single_update(barcode, payload) #pass data to update as payload

        if result[:status].start_with?('Success')
          mutex.synchronize {success_count += 1}
        else
          mutex.synchronize {fail_count += 1}
          puts "Fail #{result[:status]}"
        end

        result
      end

      # Write results to CSV
      write_results_csv(results, output_csv)

      # Display summary
      puts "\n" + "=" * 80
      puts "SUMMARY"
      puts "=" * 80
      puts "Total processed:  #{results.length}"
      puts "Successful operations: #{success_count}"
      puts "Failed operations: #{fail_count}"
      puts "\n Results saved to: #{output_csv}"
      puts "=" * 80

      {
        success: true,
        total: results.length,
        successful: success_count,
        failed: fail_count,
        results: results
      }
    rescue StandardError => e
      puts "\n Error during batch processing: #{e.message}"
      puts e.backtrace.first(5)
      { success: false, error: e.message}
    end

    #process a single vial: find uid and update with payload
    # @param barcode [String] Vial barcode
    # @param payload [Hash] Fields to update
    # @return [Hash] Result data for this vial
    def process_single_update(barcode, payload)
      result_data = {
        barcode: barcode,
        status: ''
      }

      # Step 1: Find vial by barcode to retreive uid
      search_result = Vial.find_vial_by_vial_barcode(barcode, verbose: false)

      unless search_result[:success]
        result_data[:status] = "F: API Error - #{search_result[:error]}"
        return result_data
      end

      if search_result[:count] == 0
        result_data[:status] = "F: No vial found"
        return result_data
      end

      # Step 2: Extract vial data
      vial_id = search_result[:data].first['id']
      
      # Step 3: Update vial data
      update_result = Vial.update_vial_by_vial_id(vial_id, payload: payload, verbose: false)

      if update_result[:success]
        result_data[:status] = "Success"
      else
        result_data[:status] = "F: Not updated - #{update_result[:error]}"
      end

      result_data
    rescue StandardError => e
      result_data[:status] = "F: Exception - #{e.message}"
      result_data
    end
  
    # write results to csv file
    # @param results [Array] Array of result hashes
    # @param output_file [String] Output csv filename
    def write_results_csv(results, output_file)
      CSV.open(output_file, 'w', col_sep: ';') do |csv|
        csv << ['Vial barcode', 'Status']
        results.each do |result|
          csv << [result[:barcode], result[:status]]
        end
      end
    end

end

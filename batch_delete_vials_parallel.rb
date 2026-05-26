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
require 'parallel'

module BatchVialOperationsParallel
  extend self

  # Delete vials from CSV file containing barcodes
  # @param input_csv [String] Path to input CSV file with barcodes
  # @param output_csv [String] Path to output results CSV file
  # @param barcode_column [String, Integer] Column name or index containing barcodes (default: 0)
  # @return [Hash] Summary of operation
  def batch_delete_w_barcode(input_csv:, output_csv: 'deletion_results.csv', barcode_column: 0, threads: 50)
    unless File.exist?(input_csv)
      puts "❌ Error: Input file '#{input_csv}' not found"
      return { success: false, error: "File not found" }
    end

    # Read all rows to array so deletion can be parallelized
    rows = []
    CSV.foreach(input_csv, headers: true) do |row|
      barcode = if barcode_column.is_a?(Integer) || barcode.is_a?(String)
                  row[barcode_column]
                else
                  row[0]
                end
      rows << barcode.strip unless barcode.nil? || barcode.strip.empty?
    end

    puts "\n" + "=" * 80
    puts "BATCH VIAL DELETION"
    puts "=" * 80
    puts "Input file: #{input_csv}"
    puts "Output file: #{output_csv}"
    puts "Threads: #{threads}"
    puts "\nProcessing #{rows.length} vials...\n"

    mutex = Mutex.new
    found_count = 0
    not_found_count = 0

    results = Parallel.map(rows, in_threads: threads) do |barcode|
      sleep(rand(5.0..10.0)) #randomized delay to avoid synchronized bursts
      puts "Deleting barcode: #{barcode}... \n"

      result = process_single_vial(barcode)
            
      if result[:status].start_with?('Success')
        mutex.synchronize {success_count += 1}
        puts "✅ #{result[:status]}"
      else
        mutex.synchronize {fail_count += 1}
        puts "❌ #{result[:status]}"
      end
      result
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
    search_result = Vial.find_by_barcode(barcode, verbose: false)

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

  # Dry run: Find vials but don't delete (for testing)
  # @param input_csv [String] Path to input CSV file with barcodes
  # @param output_csv [String] Path to output results CSV file
  # @param barcode_column [String, Integer] Column name or index containing barcodes
  # @return [Hash] Summary of operation
  def dry_run_w_barcode(input_csv:, output_csv: 'dry_run_results.csv', barcode_column: 0, threads: 10)
    unless File.exist?(input_csv)
      puts "❌ Error: Input file '#{input_csv}' not found"
      return { success: false, error: "File not found" }
    end
 
    # Read all rows upfront so search can parallelize
    rows = []
    CSV.foreach(input_csv, headers: true) do |row|
      barcode = if barcode_column.is_a?(Integer) || barcode_column.is_a?(String)
                  row[barcode_column]
                else
                  row[0]
                end
      rows << barcode.strip unless barcode.nil? || barcode.strip.empty?
    end
 
    puts "\n" + "=" * 80
    puts "DRY RUN - VIAL LOOKUP (NO DELETION)"
    puts "=" * 80
    puts "Input file: #{input_csv}"
    puts "Output file: #{output_csv}"
    puts "Threads: #{threads}"
    puts "\nProcessing #{rows.length} vials...\n"
 
    mutex = Mutex.new
    found_count = 0
    not_found_count = 0
    box_cache = {}          #Cache: box_id => {name, bc, container_id}
    freezer_cache = {}      #Cache: freezer_id => {name, bc}
    sample_type_cache = {}  #Cache: sample_type_id => {name}
    subdivision_cache = {}  #Cache: container_id => {name, bc, parent id}
     
    results = Parallel.map(rows, in_threads: threads) do |barcode|
      #sleep(rand(0.1..0.5)) #randomized delay to avoid synchronized bursts
      sleep(rand(5.0..10.0)) #randomized delay to avoid synchronized bursts
      puts "Checking barcode: #{barcode}... \n"
 
      result_data = {
        barcode: barcode,
        sample_id: '',
        sample_type_id: '',
        sample_type_name: '',
        freezer_name: '',
        freezer_barcode: '',
        subdivision_name: '',
        subdivision_bc: '',
        subdivision_parent: '',
        container_id: '',
        box_id: '',
        box_bc: '',
        box_name: '',
        position: '',
        volume: '',
        status: ''
      }
 
      vial_result = Vial.find_vial_by_vial_barcode(barcode, verbose: false) #filtered search
      if vial_result[:success] && vial_result[:count] > 0
       vial = vial_result[:data].first
       vial_attrs = vial['attributes']
       vial_relate = vial['relationships']
       result_data[:sample_id] = vial_attrs['sample_id'].to_s  ##this the same as relate/sample/data/id?
       #result_data[:sample_id2] = vial_relate.dig('sample', 'data', 'id')
       #puts "Sample_id: #{result_data[:sample_id]}\nSample_id2: #{result_data[:sample_id2]}\n"
       result_data[:box_id] = vial_relate.dig('box', 'data', 'id').to_s
       result_data[:position] = vial_attrs['position'].to_s
       result_data[:volume] = vial_attrs['volume'].to_s

      box_id = result_data[:box_id].to_s
      if !box_id.empty?
        cached_box = mutex.synchronize { box_cache[box_id] }
        if cached_box
          result_data[:box_bc] = cached_box[:bc]
          result_data[:box_name] = cached_box[:name]
          container_id = cached_box[:container_id]
          result_data[:container_id] = container_id
        else
          box_result = Box.retreive_box(box_id, verbose: false)  # direct lookup by id instead of vial barcode
          if box_result[:success] && box_result[:count] > 0
            #puts "box result is: ", box_result.class
            box = box_result[:data]
            box_attrs = box['attributes']
            box_relate = box['relationships']
            box_bc = box_attrs['barcode_tag'].to_s
            box_name = box_attrs['name'].to_s
            container_id = box_relate.dig('container', 'data', 'id').to_s
            result_data[:box_bc] = box_bc
            result_data[:box_name] = box_name
            result_data[:container_id] = container_id
            mutex.synchronize { box_cache[box_id] = { bc: box_bc, name: box_name, container_id: container_id } }
          end
        end
      end

       # Lookup sample type id using vial barcode (depends on sample_id)
      sample_type_id = nil #to avoid problems if sample_id lookup fails
      if !result_data[:sample_id].empty?
        #sample_result = Sample.get_sample_by_vial_barcode(barcode, verbose: false) #filtered search
        sample_result = Sample.retreive_sample(result_data[:sample_id], verbose: false) #direct search
        if sample_result[:success] && sample_result[:count] > 0
          ##puts "Sample result is: ", sample_result.class
          sample_type_id = sample_result[:data].dig('relationships', 'sample_type', 'data', 'id').to_s
          result_data[:sample_type_id] = sample_type_id
        end
      end
 
      # Lookup sample type name using sample type id (cached)
      # Warning this is very slow when using filtering by vial barcode, hence direct retreive by id!
      if !sample_type_id.to_s.empty?
        cached_sample_type = mutex.synchronize {sample_type_cache[sample_type_id]}
        if cached_sample_type
          result_data[:sample_type_name] = cached_sample_type[:name]
        else
          sample_type_result = Sample_Type.retreive_sample_type(sample_type_id, verbose: false) #direct search
          #sample_type_result = Sample_Type.get_sample_type_by_vial_barcode(barcode, verbose: true) #works but super slow
          if sample_type_result[:success] && sample_type_result[:count] > 0
            ##puts "sample type result is: ", sample_type_result.class 
            sample_type_attrs = sample_type_result[:data].dig('attributes')  # not an array skip .first
            name = sample_type_attrs['name'].to_s
            result_data[:sample_type_name] = name
            mutex.synchronize { sample_type_cache[sample_type_id] = {name: name}}
          end
        end
      end
 
      # Lookup Subdivision using container_id cached.
      # Note: subdivision searches against the Container endpoint
      container_id = result_data[:container_id].to_s
      if !container_id.empty?
        cached_subdivision = mutex.synchronize {subdivision_cache[container_id]}
        if cached_subdivision
          result_data[:subdivision_name] = cached_subdivision[:name]
          result_data[:subdivision_bc] = cached_subdivision[:bc]
          result_data[:subdivision_parent] = cached_subdivision[:parent_id]
        else
          subdivision_result = Subdivision.retreive_subdivision(container_id, verbose: false)
          if subdivision_result[:success] && subdivision_result[:count] > 0
            ##puts "Subdivision result is: ", subdivision_result.class
            subdivision = subdivision_result[:data]
            subdivision_attrs = subdivision['attributes']
            subdivision_relate = subdivision['relationships']
            subdivision_name = subdivision_attrs['name'].to_s
            subdivision_bc = subdivision_attrs['barcode_tag'].to_s
            parent_id = subdivision_relate.dig('parent', 'data', 'id').to_s
            result_data[:subdivision_name] = subdivision_name
            result_data[:subdivision_bc] = subdivision_bc
            result_data[:subdivision_parent] = parent_id
            mutex.synchronize { subdivision_cache[container_id] = {name: subdivision_name, bc: subdivision_bc, parent_id: parent_id}}
          end
        end
      end

      # Lookup Freezer using subdivision parent_id (cached)
      freezer_id = result_data[:subdivision_parent].to_s
      if !freezer_id.empty?
        cached_freezer = mutex.synchronize {freezer_cache[freezer_id]}
        if cached_freezer
          result_data[:freezer_name] = cached_freezer[:name]
          result_data[:freezer_barcode] = cached_freezer[:bc]
        else
          freezer_result = Freezer.retreive_freezer(freezer_id, verbose: false)
          if freezer_result[:success] && freezer_result[:count] > 0
            freezer = freezer_result[:data]
            freezer_attrs = freezer['attributes']
            freezer_name = freezer_attrs['name'].to_s
            freezer_bc = freezer_attrs['barcode_tag'].to_s
            result_data[:freezer_name] = freezer_name
            result_data[:freezer_barcode] = freezer_bc
            mutex.synchronize { freezer_cache[freezer_id] = {name: freezer_name, bc: freezer_bc}}
          end
        end
      end
        
      result_data[:status] = "Found (would delete)"
      mutex.synchronize { found_count += 1 }
      #puts "✅ Found"
      else
      result_data[:status] = "Not found"
      mutex.synchronize { not_found_count += 1 }
      #puts "❌ Not found"
      end
 
      result_data
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

  # Write results to CSV file
  # @param results [Array] Array of result hashes
  # @param output_file [String] Output CSV filename
  def write_results_csv(results, output_file)
    CSV.open(output_file, 'w') do |csv|
      # Write header
      #csv << ['Vial barcode','Sample id', 'Sample type id', 'Sample type name', 'Freezer name', 'Freezer BC', 'Subdivision name', 'Subdivision BC', 'Box ID', 'Box BC', 'Box name', 'Position', 'Volume', 'Status']
      csv << ['Vial barcode','Sample id', 'Sample type id', 'Sample type name', 'Freezer name', 'Subdivision name', 'Box ID', 'Box name', 'Position', 'Volume', 'Status']
      # Write data rows
      results.each do |result|
        csv << [
          result[:barcode],
          result[:sample_id],
          result[:sample_type_id],
          result[:sample_type_name],
          result[:freezer_name],
          #result[:freezer_barcode],
          result[:subdivision_name],
          #result[:subdivision_bc],
          result[:box_id],
          #result[:box_bc],
          result[:box_name],
          result[:position],
          result[:volume],
          result[:status]
        ]
      end
    end
  end


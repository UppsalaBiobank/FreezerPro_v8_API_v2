# Module-specific wrappers — each is a one-liner delegating to API.retreive
# Adding a new resource type only requires adding a new module with one method

module Audit_Records
  extend self
  # @param uid [String, Integer] Audit record ID
  # @param verbose [Boolean] Whether to print status messages
  # @return [Hash] Response hash with :success, :data, :count, or :error
  def retreive_audit_record(uid, verbose: true) #Single record
    API.retreive(uid, endpoint: 'audit_records', verbose: verbose)
  end
  
  # Filtering supported using the following operators: eq, neq, cont, gt, lt
  def list_audit_records(filters: nil, verbose: true)
    API.list(endpoint: 'audit_records', filters: filters, verbose: verbose)
  end
end

module Box
  extend self
  # @param uid [String, Integer] Box ID
  # @param verbose [Boolean] Whether to print status messages
  # @return [Hash] Response hash with :success, :data, :count, or :error
  def retreive_box(uid, verbose: true) #Single record
    API.retreive(uid, endpoint: 'boxes', verbose: verbose)
  end

  # # Filtering supported using the following operators: eq, neq, cont, gt, lt
  def list_boxes(filters: nil, verbose: true)
    API.list(endpoint: 'boxes', filters: filters, verbose: verbose)
  end

  def get_box_by_vial_barcode(vial_bc, verbose: true)
    list_boxes(filters: {'vial_barcode_eq' => vial_bc.to_s}, verbose: verbose)
  end

  def get_box_by_box_barcode(box_bc, verbose: true)
    list_boxes(filters: {'barcode_eq' => box_bc.to_s}, verbose: verbose)
  end

  def get_box_by_id(box_id, verbose: true)
    list_boxes(filters: {'id_eq' => box_id.to_s}, verbose: verbose)
  end

  def get_box_by_name(box_name_fragment, verbose: true)
    list_boxes(filters: {'name_cont' => box_name_fragment.to_s}, verbose: verbose)
  end
end

module Container
  extend self
  # @param uid [String, Integer] Container ID
  # @param verbose [Boolean] Whether to print status messages
  # @return [Hash] Response hash with :success, :data, :count, or :error
  def retreive_container(uid, verbose: true) #Single record
    API.retreive(uid, endpoint: 'containers', verbose: verbose)
  end
end
 
module Freezer
  extend self
  # @param uid [String, Integer] Freezer ID
  # @param verbose [Boolean] Whether to print status messages
  # @return [Hash] Response hash with :success, :data, :count, or :error
  def retreive_freezer(uid, verbose: true) #Single record
    API.retreive(uid, endpoint: 'freezers', verbose: verbose)
  end

  # Filtering supported using the following operators: eq, neq, cont, gt, lt
  def list_freezers(filters: nil, verbose: true)
    API.list(endpoint: 'freezers', filters: filters, verbose: verbose)
  end

  def get_freezer_by_freezer_barcode(freezer_bc, verbose: true)
    list_freezers(filters: {'barcode_eq' => freezer_bc.to_s}, verbose: verbose)
  end

  def get_freezer_by_name(freezer_name_fragment, verbose: true)
    list_freezers(filters: {'name_cont'=> freezer_name_fragment.to_s}, verbose: verbose)
  end

  def get_freezer_by_vial_barcode(vial_bc, verbose: true) ##will most likely not work according to API. Keep for testing.
    list_freezers(filters: {'vial_barcode_eq' => vial_bc.to_s}, verbose: verbose)
  end
end

module Sample
  extend self
  # @param uid [String, Integer] Sample ID
  # @param verbose [Boolean] Wether to print status message
  # @return [Hash] Response hash with :success, :data, :count, or :error
  def retreive_sample(uid, verbose: true) #Single record
    API.retreive(uid, endpoint: 'samples', verbose: verbose)
  end

  # Filtering supported using the following operators: eq, neq, cont, gt, lt
  def list_samples(filters: nil, verbose: true)
    API.list(endpoint: 'samples', filters: filters, verbose: verbose)
  end

  def get_sample_by_vial_barcode(vial_bc, verbose: true)
    list_samples(filters: {'vial_barcode_eq' => vial_bc.to_s}, verbose: verbose)
  end

  def get_sample_by_name(sample_name_fragment, verbose: true)
    list_samples(filters: {'name_cont' => sample_name_fragment.to_s}, verbose: verbose)
  end
end

module Sample_Source
  extend self
  # @param uid [String, Integer] Sample source ID
  # @param verbose [Boolean] Wether to print status message.
  # @return [Hash] Response hash with :success, :data, :count, or :error
  def retreive_sample_source(uid, verbose: true) #Single record
    API.retreive(uid, endpoint: 'sample_sources', verbose: verbose)
  end

  # Filtering supported using the following operators: eq, neq, cont, gt, lt
  def list_sample_sources(filters: nil, verbose: true)
    API.list(endpoint: 'sample_sources', filters: filters, verbose: verbose)
  end

  def get_sample_sources_by_type(type_id, verbose: true)
    list_sample_sources(filters: {'type_id_eq' => type_id.to_s}, verbose: verbose)
  end

  def get_sample_source_name(name_fragment, verbose: true)
    list_sample_sources(filters: {'name_cont' => name_fragment.to_s}, verbose: verbose)
  end

  def get_sample_by_vial_barcode(vial_bc, verbose: true) ##will most likely not work according to API. Keep for testing.
    list_sample_sources(filters: {'vial_barcode_eq' => vial_bc}, verbose: verbose)
  end
end

module Sample_Type
  extend self
  # @param uid [String, Integer] Sample type ID
  # @param verbose [Boolean] Whether to print status messages
  # @return [Hash] Response hash with :success, :data, :count, or :error
  def retreive_sample_type(uid, verbose: true) #Single record
    API.retreive(uid, endpoint: 'sample_types', verbose: verbose)
  end

  # Filtering supported using the following operators: eq, neq, cont, gt, lt
  def list_sample_types(filters: nil, verbose: true)
    API.list(endpoint: 'sample_types', filters: filters, verbose: verbose)
  end

  def get_sample_type(sample_type_id, verbose: true)
    list_sample_types(filters: {'id_eq' => sample_type_id.to_s}, verbose: verbose)
  end

  def get_sample_type_by_vial_barcode(vial_bc, verbose: true) ##will most likely not work according to API. Keep for testing.
    list_sample_types(filters: {'vial_barcode_eq' => vial_bc.to_s}, verbose: verbose)
  end
end 

module Subdivision
  extend self
  # @param uid [String, Integer] Subdivision ID
  # @param verbose [Boolean] Whether to print status messages
  # @return [Hash] Response hash with :success, :data, :count, or :error
  def retreive_subdivision(uid, verbose: true) #Single record
    API.retreive(uid, endpoint: 'subdivisions', verbose: verbose)
  end

  # Filtering supported using the following operators: eq, neq, cont, gt, lt
  def list_subdivisions(filters: nil, verbose: true)
    API.list(endpoint: 'subdivisions', filters: filters, verbose: verbose)
  end

  def get_subdivision_by_name(subdivision_name_fragment, verbose: true)
    list_subdivisions(filters: {'name_cont' => subdivision_name_fragment.to_s}, verbose: verbose)
  end

  def get_subdivision_by_barcode(subdivision_bc, verbose: true)
    list_subdivisions(filters: {'barcode_eq' => subdivision_bc}, verbose: verbose)
  end

  def get_subdivision_by_vial_bc(vial_bc, verbose: true) ##does not work. "Invalid standard field"
    list_subdivisions(filters: {'vial_barcode_eq' => vial_bc}, verbose: verbose)
  end
end

module Vial
  extend self
  # @param uid [String, Integer] Vial ID
  # @param verbose [Boolean] Whether to print status messages
  # @return [Hash] Response hash with :success, :data, :count, or :error
  def retreive_vial(uid, verbose: true) #Single record
    API.retreive(uid, endpoint: 'vials', verbose: verbose)
  end

  # Filtering supported using the following operators: eq, neq, cont, gt, lt
  def list_vials(filters: nil, verbose: true)
    API.list(endpoint: 'vials', filters: filters, verbose: verbose)
  end

  def find_vial_by_sample_id(sample_id, verbose: true)
    list_vials(filters: {'sample_id_eq' => sample_id.to_s}, verbose: verbose)
  end

  def find_vial_by_box_id(box_id, verbose: true)
    list_vials(filters: {'box_id_eq' => box_id.to_s}, verbose: verbose)
  end

  def find_vial_by_vial_barcode(vial_bc, verbose: true)
    list_vials(filters: {'barcode_eq' => vial_bc.to_s}, verbose: verbose)
  end

  def find_vial_by_sample_type_id(sample_type_id, verbose: true)
    list_vials(filters: {'sample_type_id_eq' => sample_type_id.to_s}, verbose: verbose)
  end
end

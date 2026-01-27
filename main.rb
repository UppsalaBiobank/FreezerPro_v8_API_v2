#$LOAD_PATH << '/menu_files/' #
#Dir[File.join(__dir__, 'lib', '*.rb')].each { |file| require file }
require 'net/http'
require 'json'
require 'time'
require 'csv'
require_relative './menu_files/set_server'
require_relative './menu_files/credentials'
require_relative './menu_files/select_file'
require_relative './menu_files/gen_token'
require_relative './menu_files/countdown'
require_relative './menu_files/try'
require_relative './audit_records'
require_relative './sample'
require_relative './sample_source'
require_relative './sample_type'
require_relative './vial'
require_relative './box'
require_relative './display_helpers'
require_relative './batch_delete_vials'
#require_relative './menu_files/main_menu'
#puts 'br1 in main' ###used during testing###
#include Set_Server
include Credentials
include Select_File
include Try

#main_ui

###set_server###
Set_Server.select_server(2) ### 1 == prod, 2 == test
puts "Current server is #{$menu_print}"

###set login method### -static credentials should only be used during dev.
#variable_credentials
static_credentials

###generate token for use in api-calls
auth_result = Gen_Token.logon_for_token($user, $password)
unless auth_result[:success]
  puts "Login failed: #{auth_result[:error]}"
  exit 1
end

puts "Login successful! Token expires at: #{$token_expires}"
#Countdown.has_token_expired

## call method of your choosing e.g 
=begin
# Display helpers
result = Vial.find_by_barcode(1011857)
DisplayHelpers.display_vials(result, title: 'Vials with barcode 1011857')

# Example 2: Display sample sources
result = SampleSource.list_sample_sources(filters: { 'name_cont' => 'patient' })
DisplayHelpers.display_sample_sources(result, title: "PATIENT SAMPLE SOURCES")

# Example 3: Display audit records
result = AuditRecord.get_recent_audit_records('01/01/2024')
DisplayHelpers.display_audit_records(result, title: "RECENT AUDIT RECORDS")

# Example 4: Simple list view
result = Vial.get_vials_out_of_freezer()
DisplayHelpers.display_list(result, fields: ['id', 'name', 'barcode_tag'])

# Example 5: Export to CSV
result = Sample.list_samples()
DisplayHelpers.export_to_csv(
  result, 
  fields: ['name', 'description', 'created_at'],
  filename: 'samples_export.csv'
)

# Example 6: Interactive selection
result = Sample.list_samples(filters: { 'name_cont' => 'Bacteria' })
selected_sample = DisplayHelpers.interactive_select(result)

# Example 7: Display summary stats
result = Vial.list_vials()
DisplayHelpers.display_summary(result)

=end

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
require_relative './api_helper'
require_relative './api_endpoints'
require_relative './batch_delete_vial_parallel'

###set_server###
Set_Server.select_server(2) ### 1 == prod, 2 == test
puts "Current server is #{$menu_print}"

###set login method### -static credentials should only be used during dev.
#Credentials.variable_credentials()
Credentials.static_credentials()

###generate token for use in api-calls
#Gen_Token.logon_for_token($user, $password)
auth_result = Gen_Token.logon_for_token($user, $password)
unless auth_result[:success]
  puts "Login failed:  #{auth_result[:error]}]"
  exit 1
end

puts "Login successful! Token expires at: #{$token_expires}"


# Dry run
puts "\n Running dry run to check what will be deleted"
results = BatchVialOperationsParallel.dry_run_from_csv(input_csv: './csv/_test.csv', output_csv: './csv/dry_run_results.csv')
if results[:success]
  puts "\n Review dry_run_results.csv before proceeding."
  printf "Continue with deletion? (y/n): "
  confirmation = gets.chomp.downcase
else
  exit 1
end

if confirmation == 'y'
  #Warning, actual deletion will be performed!
  results = BatchVialOperations.batch_delete_from_csv(input_csv: './csv/_test.csv', output_csv: './csv/_results.csv')
  if results[:success]
    puts "\n Batch deletion completed"
    puts "Check result csv for details."
  else
    exit 1
  end
end
if confirmation == 'n'
  puts "\n 'No' entered. Batch deletion cancelled."
  exit 1
end

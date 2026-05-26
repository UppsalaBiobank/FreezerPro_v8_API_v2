module Credentials
    extend self
    
    def variable_credentials()
        print "Enter username: "
        $user = gets.chomp
        while $user == ""
            puts "No username provided"
            puts "Enter username: "
            $user = gets.chomp
        end
        #$username = "|     #{$user}                |\n"
        print "Enter password: "
        $password = gets.chomp
        while $password == ""
            puts "No password provided"
            puts "Enter password: "
            $password = gets.chomp
        end
    end

    def static_credentials()
    #static credentials should only be used for testing.
    #change username and password to the static login/pass you want to use
    $user = 'xx'
    $password = 'yy'
    end
end

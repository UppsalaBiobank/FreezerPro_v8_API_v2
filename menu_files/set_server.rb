require 'uri'
module Set_Server
    extend self
    #def set_to_prod()        
    #    #webadress to FP prod
    #    #$current_server = URI.parse('https://freezerpro.regionuppsala.se')
    #    $current_server = 'https://freezerpro.regionuppsala.se'
    #    $menu_print = "|          #{$current_server.to_s}       |\n"
    #end
#
    #def set_to_test()        
    #    #webadress to FP test.
    #    #$current_server = URI.parse('https://freezerpro-test.regionuppsala.se')
    #    $current_server = 'https://freezerpro-test.regionuppsala.se'
    #    $menu_print = "|     #{$current_server.to_s}       |\n"
    #end

    def select_server(select_value)
        if select_value == 1
            $current_server = 'https://freezerpro.regionuppsala.se'

        elsif select_value == 2
            $current_server = "https://freezerpro-test.regionuppsala.se"
        
        end
        $menu_print = "|          #{$current_server.to_s}       |\n"
    end
end

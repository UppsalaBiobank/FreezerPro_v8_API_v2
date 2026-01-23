#countdown
#check whether token still is valid when an API call is made
require 'time'
module Countdown
    def has_token_expired
        curr_time = Time::new
        formated_time = '%H:%M:%S'
        a = curr_time.strftime(formated_time)
        b = $token_expires
        b = Time.parse(b)
        b = b.strftime(formated_time)
        if a < b
            puts 'token should still be valid'
        else
            puts "token has expired"
        end
    end
    extend self
end

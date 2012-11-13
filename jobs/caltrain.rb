require_relative '../lib/caltrain'

SCHEDULER.every '30s', :first_in => 0 do |job|
    send_event('caltrain', Caltrain.get_next_trains(2, "Mountain View"))
end


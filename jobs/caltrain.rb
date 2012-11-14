require_relative '../lib/caltrain'

SCHEDULER.every '30s', :first_in => 0 do |job|
    send_event('caltrain_north', Caltrain.get_next_trains_for_direction(2, "Mountain View", "northbound"))
    send_event('caltrain_south', Caltrain.get_next_trains_for_direction(2, "Mountain View", "southbound"))
end


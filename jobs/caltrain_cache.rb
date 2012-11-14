require_relative '../lib/caltrain'

SCHEDULER.every '24h', :first_in => 0 do |job|
    send_event('caltrain', Caltrain.cache_train_schedule())
end

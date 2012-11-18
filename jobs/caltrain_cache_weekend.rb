require_relative '../lib/caltrain'

SCHEDULER.cron '0 0 * * 6-7' do |job|
    send_event('caltrain', Caltrain.cache_train_schedule('weekend'))
end

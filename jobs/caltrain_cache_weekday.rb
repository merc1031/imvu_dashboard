require_relative '../lib/caltrain'

SCHEDULER.cron '0 0 * * 1-5' do |job|
    send_event('caltrain', Caltrain.cache_train_schedule('weekday'))
end

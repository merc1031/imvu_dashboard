require "net/http"

def get_pulled_slave_count (type)
    # we're running this so infrequently that it doesn't matter that we have to reparse this every time
    base_uri = URI.parse('http://engprocess.corp.imvu.com/buildslaves/api/get.php');
    base_uri.query = URI.encode_www_form({ :category => type, :status => 'pulled'})
    response = Net::HTTP.get_response(base_uri)
    response.body.lines.count if response.is_a?(Net::HTTPSuccess)
end

# :first_in sets how long it takes before the job is first run. In this case, it is run immediately
SCHEDULER.every '10m', :first_in => 0 do |job|
  send_event('web_pulled_slaves', { current: get_pulled_slave_count('web') })
  send_event('client_pulled_slaves', { current: get_pulled_slave_count('client') - 4 }) # there are 4 slaves that show up that don't actually appear on client bb
end

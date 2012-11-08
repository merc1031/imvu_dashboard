require "net/http"

def get_push_status (source)
    base_uri = URI.parse('http://engprocess.corp.imvu.com/buildslaves/api/build_metadata.php');
    base_uri.query = URI.encode_www_form({ :action => 'get', :key => "{source}_push_status"})
    response = Net::HTTP.get_response(base_uri)
    if response.is_a?(Net::HTTPSuccess)
        body = JSON.decode(response.body)
        return body
    end
    return {}
end

SCHEDULER.every '30s', :first_in => 0 do |job|
  send_event('push_status', {})
end

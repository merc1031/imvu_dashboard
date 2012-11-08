require 'net/http'
require 'json'

def get_push_status (source)
    base_uri = URI.parse('http://engprocess.corp.imvu.com/buildslaves/api/build_metadata.php');
    base_uri.query = URI.encode_www_form({ :action => 'get', :key => "#{source}_push_status"})
    response = Net::HTTP.get_response(base_uri)
    if response.is_a?(Net::HTTPSuccess)
        body = JSON.parse(response.body)
        return JSON.parse(body['value'])
    end
    return {}
end

def get_all_push_statuses
    keys = ['imvu_website', 'imvu_imq', 'paris_website', 'paris_imq', 'assetserver']
    return Hash[keys.collect { |key| [key, get_push_status(key)] }]
end

SCHEDULER.every '30s', :first_in => 0 do |job|
    send_event('push_status', { :statuses => get_all_push_statuses })
end

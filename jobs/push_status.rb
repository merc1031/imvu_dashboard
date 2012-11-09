require 'net/http'
require 'json'

def get_build_metadata (key)
    base_uri = URI.parse('http://engprocess.corp.imvu.com/buildslaves/api/build_metadata.php');
    base_uri.query = URI.encode_www_form({ :action => 'get', :key => key })
    response = Net::HTTP.get_response(base_uri)
    if response.is_a?(Net::HTTPSuccess)
        return JSON.parse(response.body)
    end
    return nil
end

def get_push_status (source)
    raw = get_build_metadata "#{source}_push_status"
    unless raw.nil?
        data = JSON.parse(raw['value'])
        rev_in_production = get_current_revision source
        data['rev_in_production'] = rev_in_production
        data['start'] = data['start'][11, 8]
        data['rev'] = data['rev'][0, 8]
        data['end'] = data['end'][10, 8] unless data['end'].nil?

        if data['end'].nil?
            data['status'] = -1
        elsif rev_in_production == data['rev']
            data['status'] = 1
        else
            data['status'] = 0
        end

        return data
    end
    return {}
end

def get_current_revision (source)
    data = get_build_metadata "#{source}_rev_in_production"
    unless data.nil?
        return data['value'][0, 8]
    end
    return 'UNKNOWN'
end

def get_all_push_statuses
    keys = ['imvu_website', 'imvu_imq', 'paris_website', 'paris_imq', 'assetserver']
    return Hash[keys.collect { |key| [key, get_push_status(key)] }]
end

SCHEDULER.every '30s', :first_in => 0 do |job|
    send_event('push_status', { :statuses => get_all_push_statuses })
end

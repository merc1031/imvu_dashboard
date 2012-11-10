require 'net/http'
require 'json'
require 'date'

def get_builder_state(root_url, slave)
    base_uri = URI.parse("http://#{root_url}/json/builders/#{slave}/builds?select=-1&select=-2");
    response = Net::HTTP.get_response(base_uri)
    if response.is_a?(Net::HTTPSuccess)
        JSON.parse(response.body)
    end
end

def get_builders(root_url)
    base_uri = URI.parse("http://#{root_url}/json/builders/");
    response = Net::HTTP.get_response(base_uri)
    if response.is_a?(Net::HTTPSuccess)
        JSON.parse(response.body)
    end
end

def get_current_build(root_url)
    base_uri = URI.parse("http://#{root_url}/json/builders/aggregator/builds/-1/");
    response = Net::HTTP.get_response(base_uri)
    if response.is_a?(Net::HTTPSuccess)
        JSON.parse(response.body)
    end
end

def get_aggregator(root_url)
    base_uri = URI.parse("http://#{root_url}/json/builders/aggregator/");
    response = Net::HTTP.get_response(base_uri)
    if response.is_a?(Net::HTTPSuccess)
        JSON.parse(response.body)
    end
end

def get_builders_data(buildbot)
    build_data = get_builders buildbot
    success_count = 0
    failure_count = 0
    warnings_count = 0
    skipped_count = 0
    exception_count = 0
    retry_count = 0
    unless build_data.nil?
        build_data.each { |n, v|
            state = get_builder_state buildbot, n
            builder_state = state['-1']['results']
            #if state['-1']['result'].nil?
            #    builder_state = state['-2']['results']
            #end

            if builder_state == 0 
                success_count += 1
            end
            if builder_state == 2
                failure_count += 1
            end
            if builder_state == 1
                warnings_count += 1
            end
            if builder_state == 3
                skipped_count += 1
            end
            if builder_state == 4
                exception_count += 1
            end
            if builder_state == 5
                retry_count += 1
            end
        }
        data =  
        {
            :success => success_count,
            :failed => failure_count,
            :warnings => warnings_count,
            :skipped => skipped_count,
            :exception => exception_count,
            :retry => retry_count
        }
    else
        {}
    end
end

def get_build_data(buildbot)
    build_data = get_current_build buildbot
    aggregator_data = get_aggregator buildbot
    unless build_data.nil? or aggregator_data.nil?
        times = extract_times build_data
        {
            :revisions => extract_revisions(build_data),
            :state => extract_state(build_data, aggregator_data),
            :start => times[0],
            :end => times[1],
            :queue => aggregator_data['pendingBuilds'] || 0
        }
    else
        {}
    end
end

def extract_revisions(data)
    data['sourceStamp']['changes'].collect { |change| { :user => change['who'], :rev => change['rev'] } }
end

def extract_state(build_data, aggregator_data)
    if build_data['text'].include? 'failure'
        'failure'
    elsif build_data['text'].include? 'exception'
        'exception'
    else
        aggregator_data['state'] || 'unkown'
    end
end

def extract_times(data)
    data['times'].collect { |time| Time.at(time).strftime('%T') unless time.nil? }
end

SCHEDULER.every '20s', :first_in => 0 do |job|
  send_event('web_hypo_buildbot', { :status => get_builders_data('hypothesisbuildbot.corp.imvu.com:8010') } )
    #send_event('web_buildbot', get_build_data('webbuildbot'))
  #send_event('web_hypo_buildbot', get_build_data('hypothesisbuildbot.corp.imvu.com:8010'))
end

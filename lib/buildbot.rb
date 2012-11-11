require 'net/http'
require 'json'
require 'date'

module Buildbot

    def self.get_build(root_url, build)
        base_uri = URI.parse("http://#{root_url}/json/builders/aggregator/builds/#{build}/");
        response = Net::HTTP.get_response(base_uri)
        if response.is_a?(Net::HTTPSuccess)
            JSON.parse(response.body)
        end
    end

    def self.get_current_build(root_url)
        get_build(root_url, -1)
    end

    def self.get_last_build(root_url)
        get_build(root_url, -2)
    end

    def self.get_aggregator(root_url)
        base_uri = URI.parse("http://#{root_url}/json/builders/aggregator/");
        response = Net::HTTP.get_response(base_uri)
        if response.is_a?(Net::HTTPSuccess)
            JSON.parse(response.body)
        end
    end

    def self.get_build_data(buildbot)
        build_data = get_current_build(buildbot)
        aggregator_data = get_aggregator(buildbot)
        last_build_data = get_last_build(buildbot)
        unless build_data.nil? or aggregator_data.nil?
            times = extract_times build_data
            {
                :revisions => extract_revisions(build_data),
                :start => times[0],
                :end => times[1],
                :queue => aggregator_data['pendingBuilds'] || 0,
                :state => extract_state(build_data, aggregator_data),
                :last_state => extract_state(last_build_data)
            }
        else
            {}
        end
    end

    def self.extract_revisions(data)
        data['sourceStamp']['changes'].collect { |change| { :user => change['who'], :rev => change['rev'][0, 8] } }
    end

    def self.extract_state(build_data, aggregator_data={ :state => 'idle' })
        if build_data['text'].include? 'failed'
            'failure'
        elsif build_data['text'].include? 'exception'
            'exception'
        else
            aggregator_data['state'] || 'unkown'
        end
    end

    def self.extract_times(data)
        data['times'].collect { |time| Time.at(time).strftime('%T') unless time.nil? }
    end
end

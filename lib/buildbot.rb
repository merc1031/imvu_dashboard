require 'net/http'
require 'json'
require 'date'

module Buildbot

    BUILDER_PATH = 'json/builders/aggregator/builds'
    AGGREGATOR_PATH = 'json/builders/aggregator/'

    def self.get_build(root_url, build)
        base_uri = URI.parse("http://#{root_url}/#{Buildbot::BUILDER_PATH}/#{build}/");
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
        base_uri = URI.parse("http://#{root_url}/#{Buildbot::AGGREGATOR_PATH}");
        response = Net::HTTP.get_response(base_uri)
        if response.is_a?(Net::HTTPSuccess)
            JSON.parse(response.body)
        end
    end

    def self.get_build_data(buildbot)
        current_build = get_current_build(buildbot)
        aggregator_data = get_aggregator(buildbot)
        previous_build_data = get_last_build(buildbot)
        {
            :current => extract_data(current_build, aggregator_data),
            :previous => extract_data(previous_build_data)
        }
    end

    def self.extract_data(build_data, aggregator_data=nil)
        unless build_data.nil?
            times = extract_times build_data
            {
                :revisions => extract_revisions(build_data),
                :start => times[0],
                :end => times[1],
                :queue => (aggregator_data && aggregator_data['pendingBuilds']) || 0,
                :state => extract_state(build_data, aggregator_data),
            }
        else
            {}
        end
    end

    def self.extract_revisions(data)
        data['sourceStamp']['changes'].collect { |change| { :user => change['who'], :rev => change['rev'][0, 8] } }
    end

    def self.extract_state(build_data, aggregator_data)
        if build_data['text'].include? 'failed'
            'failure'
        elsif build_data['text'].include? 'exception'
            'exception'
        elsif not aggregator_data.nil?
            aggregator_data['state'] || 'idle'
        else
            'idle' # always default to idle for now
        end
    end

    def self.extract_times(data)
        data['times'].collect { |time| Time.at(time).strftime('%T') unless time.nil? }
    end
end

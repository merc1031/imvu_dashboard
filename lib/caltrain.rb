require 'nokogiri'
require 'open-uri'
require 'net/http'
require 'json'
require 'date'

module Caltrain

    def self.get_caltrain_table()
        base_uri = URI.parse("http://www.caltrain.com/schedules/weekdaytimetable.html")
        response = Net::HTTP.get_response(base_uri)
        if response.is_a?(Net::HTTPSuccess)
            doc = Nokogiri::HTML(response.body)
            tables = doc.search('td#right table')
            data = 
            {
                :northbound => tables[1],
                :southbound => tables[2]
            }
        end
    end

    def self.extract_stop(data)
        northRow = extract_one_stop data, :northbound
        southRow = extract_one_stop data, :southbound
        data = 
        {
            :northrow => nodeset_to_inner_text(northRow),
            :southrow => nodeset_to_inner_text(southRow)
        }
    end

    def self.extract_one_stop(data, stop)
        rows = data[stop].search('tr')
        stoprow = nil 
        rows.each do |row|
            entries = row.search('th')
            name = entries[1].inner_text
            name = name.gsub /[[:space:]]/, ' '
            if name.include? "Mountain View"
                stoprow = row
                break
            end
        end
        ret = stoprow
    end

    def self.nodeset_to_inner_text(nodeset)
        nodeset.search('td').collect { |x| x.inner_text }
    end
end

require 'nokogiri'
require 'open-uri'
require 'net/http'
require 'json'
require 'date'
require 'time'

module Caltrain

    class CaltrainBase

        def initialize(period, noonSwitchOver, badHeads)
            @period = period
            @noonSwitchOver = noonSwitchOver 
            @badHeads = badHeads
        end

        def get_caltrain_table()
            base_uri = URI.parse("http://www.caltrain.com/schedules/#{@period}timetable.html")
            response = Net::HTTP.get_response(base_uri)
            if response.is_a?(Net::HTTPSuccess)
                return response.body
            end
        end

        def filter_header(row)
            row.delete_if { |x| @badHeads.include?(x.gsub /[[:space:]]/, ' ') }
        end

        def extract_header(data)
            rows = data[:northbound].search('tr')
            row = filter_header(nodeset_to_timelist rows[0], 'th')
        end

        def noon_train_index(header)
            endIndex = 0
            header.each_with_index do |item, index|
                if @noonSwitchOver.include? item
                    endIndex = index
                    break
                end
            end
            data = endIndex
        end

        def add_metadata_to( item, header_item)
            data = 
            {
                :nil => nil
            }
        end

        def add_metadata(timelist, header)
            timelist.map.with_index { |x,i| add_metadata_to x, header[i] }
        end

        def extract_stop(data, stop)
            northRow = extract_one_stop data, :northbound, stop
            southRow = extract_one_stop data, :southbound, stop
            header = extract_header data
            noonIndex = noon_train_index header
            data = 
            {
                :northbound => add_metadata(map_time(nodeset_to_timelist(northRow), noonIndex), header),
                :southbound => add_metadata(map_time(nodeset_to_timelist(southRow), noonIndex), header)
            }
        end

        def extract_one_stop(data, route, stop)
            return nil
        end
    
        def filter_time(item, index, noonIndex)
            parsedTime = '-'
            if ! item.eql? '-'
                if index >= noonIndex
                    parsedTime = (Time.parse(item) + (12 * 60 * 60)).strftime('%H:%M') 
                else
                    parsedTime = Time.parse(item).strftime('%H:%M')
                end
            end
            ret = parsedTime
        end

        def map_time(timelist, noonIndex)
            am = true
            y = nil
            timelist.each_with_index do |x,i|
                if ! x.eql? '-'
                    if !y.nil?
                        #this is sloppy and crappy. caltrain doesnt list 24h time and no indication of when it switches over
                        #and trains arent all in perfect order....
                        if Time.parse(x) - Time.parse(y) < 8 and am
                            am = false
                        elsif Time.parse(x) - Time.parse(y) < 8 and !am
                            am = true
                        end
                    end
                    if !am
                        timelist[i] = (Time.parse(x) + (12 * 60 * 60)).strftime('%H:%M')
                    else
                        timelist[i] = Time.parse(x).strftime('%H:%M')
                    end
                    y = x
                end
            end
            return timelist
            #puts timelist
            #temp = timelist.map.with_index { |x,i| filter_time x, i, noonIndex }
            #ret = temp.delete_if { |x| x.eql? '-' }
            #d = timelist
        end

        def nodeset_to_timelist(nodeset, search='td')
            #nodeset.search('td').collect { |x| x.inner_text.strip }
            nodeset.search(search).collect { |x| x.inner_text.strip }
        end

        def remove_bad_trains(train)
            train[:time].eql? '-' or time_greater_than?(Time.parse(train[:time]), Time.now)
        end

        def time_greater_than?(time1, time2)
            conv1 = Time.at(time1.hour * 60 * 60 + time1.min * 60 + time1.sec)
            conv2 = Time.at(time2.hour * 60 * 60 + time2.min * 60 + time2.sec)
            
            return conv1 < conv2
        end

        def filter_passed_trains(train_data)
            train_data.delete_if do |x|
                remove_bad_trains x
            end
        end

        def parse_caltrain_table(data)
            return nil
        end

        def cache_train_schedule()
            table = cache_train_schedule_and_return()
            data = 
            {
                :status => nil
            }
        end

        def cache_train_schedule_and_return()
            table = get_caltrain_table
            if File.exists?("/var/tmp/caltrainweekday.out")
                File.delete("/var/tmp/caltrainweekday.out")
            end
            if File.exists?("/var/tmp/caltrainweekend.out")
                File.delete("/var/tmp/caltrainweekend.out")
            end
            File.open("/var/tmp/caltrain#{@period}.out", 'w') { |f| f.write(table) }
            return table
        end

        def get_next_trains(num, stop)
            table = nil
            if File.exists?("/var/tmp/caltrain#{@period}.out") && ((Time.now - File.mtime("/var/tmp/caltrain#{@period}.out") < (24 * 60 * 60)))
                table = File.read("/var/tmp/caltrain#{@period}.out")
            else
                table = cache_train_schedule_and_return()
            end
            table = parse_caltrain_table(table)
            train_data = extract_stop(table, stop)

            data =
            {
                :northbound => filter_passed_trains(train_data[:northbound])[0..(num - 1)],
                :southbound => filter_passed_trains(train_data[:southbound])[0..(num - 1)]
            }
            return data
        end

        def get_next_trains_for_direction(num, stop, direction)
            data = get_next_trains(num, stop)
            train_status =
            {
                :status => data[direction.to_sym]
            }
        end

    end

    class CaltrainWeekend < CaltrainBase
        def initialize()
            super('weekend', ['433'], ['Train No.'])
        end

        def parse_caltrain_table(data)
            doc = Nokogiri::HTML(data)
            tables = doc.search('td#right table')
            data = 
            {
                :northbound => tables[0],
                :southbound => tables[2]
            }

        end

        def add_metadata_to( item, header_item)
            departureMayBeDelayed = false
            type = nil

            if header_item.include? '#'
                header_item = header_item.delete '#'
                departureMayBeDelayed = true
            end

            if header_item.include? 'SAT.only'
                header_item = header_item.delete 'SAT.only'
                type = "SAT only"
            end

            if Integer(header_item) >= 800
                type = "Weekend Baby Bullet"
            elsif Integer(header_item) >= 400
                type = "Local"
            end

            data =
            {
                :time => item,
                :type => type,
                :number => header_item,
                :departureMayBeDelayed => departureMayBeDelayed
            }
        end

        def extract_one_stop(data, route, stop)
            rows = data[route].search('tr')
            stoprow = nil 
            rows.each do |row|
                entries = row.search('th')
                if ! entries.nil? && ! entries[0].nil?
                    name = entries[0].inner_text
                    name = name.gsub /[[:space:]]/, ' '
                    if name.include? stop 
                        stoprow = row
                        break
                    end
                end
            end
            ret = stoprow
        end
    end

    class CaltrainWeekday < CaltrainBase
        def initialize()
            super('weekday', ['151'], ['Zone', 'Northbound Train No.'])
        end

        def parse_caltrain_table(data)
            doc = Nokogiri::HTML(data)
            tables = doc.search('td#right table')
            data = 
            {
                :northbound => tables[1],
                :southbound => tables[2]
            }
        end

        def add_metadata_to( item, header_item)
            departureMayBeDelayed = false
            type = nil

            if header_item.include? '#'
                header_item = header_item.delete '#'
                departureMayBeDelayed = true
            end

            if Integer(header_item) >= 300
                type = "Baby Bullet"
            elsif Integer(header_item) >= 200
                type = "Limited-stop"
            elsif Integer(header_item) >= 100
                type = "Local"
            end

            data =
            {
                :time => item,
                :type => type,
                :number => header_item,
                :departureMayBeDelayed => departureMayBeDelayed
            }
        end

        def extract_one_stop(data, route, stop)
            rows = data[route].search('tr')
            stoprow = nil 
            rows.each do |row|
                entries = row.search('th')
                if ! entries.nil? && ! entries[1].nil?
                    name = entries[1].inner_text
                    name = name.gsub /[[:space:]]/, ' '
                    if name.include? stop 
                        stoprow = row
                        break
                    end
                end
            end
            ret = stoprow
        end
    end
    
    def self.cache_train_schedule()
        instance = getInstance
        instance.cache_train_schedule_and_return
    end

    def self.getPeriod()
        if (1..5).include? Time.now.wday
            period = 'weekday'
        else
            period = 'weekend'
        end
    end

    def self.getInstance
        period = getPeriod
        if period == 'weekday'
            instance = CaltrainWeekday.new
        else
            instance = CaltrainWeekend.new
        end
    end

    def self.get_next_trains_for_direction(num, stop, direction)
        instance = getInstance
        instance.get_next_trains_for_direction num, stop, direction
    end
end

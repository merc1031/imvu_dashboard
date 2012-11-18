require 'nokogiri'
require 'open-uri'
require 'net/http'
require 'json'
require 'date'
require 'time'

module Caltrain

    @@noonSwitchOver = ['151','433']
    @@badHeads = ['Zone', 'Northbound Train No.', 'Train No.']
    def self.get_caltrain_table(period)
        base_uri = URI.parse("http://www.caltrain.com/schedules/#{period}timetable.html")
        response = Net::HTTP.get_response(base_uri)
        if response.is_a?(Net::HTTPSuccess)
            return response.body
        end
    end

    def self.filter_header(row)
        row.delete_if { |x| @@badHeads.include?(x.gsub /[[:space:]]/, ' ') }
    end

    def self.extract_header(data)
        rows = data[:northbound].search('tr')
        row = filter_header(nodeset_to_timelist rows[0], 'th')
    end

    def self.noon_train_index(header)
        endIndex = 0
        header.each_with_index do |item, index|
            if @@noonSwitchOver.include? item
                endIndex = index
                break
            end
        end
        data = endIndex
    end

    def self.add_metadata_to( item, header_item)
        departureMayBeDelayed = false
        type = nil

        if header_item.include? '#'
            header_item = header_item.delete '#'
            departureMayBeDelayed = true
        end

        if header_item.include? 'SAT.only'
            header_item = header_item.delete 'SAT.only'
            type = "SAT only"
        else
            if Integer(header_item) >= 800
                type = "Weekend Baby Bullet"
            elsif Integer(header_item) >= 400
                type = "Local"
            elsif Integer(header_item) >= 300
                type = "Baby Bullet"
            elsif Integer(header_item) >= 200
                type = "Limited-stop"
            elsif Integer(header_item) >= 100
                type = "Local"
            end
        end
        data =
        {
            :time => item,
            :type => type,
            :number => header_item,
            :departureMayBeDelayed => departureMayBeDelayed
        }
    end

    def self.add_metadata(timelist, header)
        timelist.map.with_index { |x,i| add_metadata_to x, header[i] }
    end

    def self.extract_stop(data, stop, period)
        northRow = extract_one_stop data, :northbound, stop, period
        southRow = extract_one_stop data, :southbound, stop, period
        header = extract_header data
        noonIndex = noon_train_index header
        data = 
        {
            :northbound => add_metadata(map_time(nodeset_to_timelist(northRow), noonIndex), header),
            :southbound => add_metadata(map_time(nodeset_to_timelist(southRow), noonIndex), header)
        }
    end

    def self.extract_one_stop(data, route, stop, period)
        index = period == 'weekday' ? 1 : 0
        rows = data[route].search('tr')
        stoprow = nil 
        rows.each do |row|
            entries = row.search('th')
            if ! entries.nil? && ! entries[index].nil?
                name = entries[index].inner_text
                name = name.gsub /[[:space:]]/, ' '
                if name.include? stop 
                    stoprow = row
                    break
                end
            end
        end
        ret = stoprow
    end
   
    def self.filter_time(item, index, noonIndex)
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

    def self.map_time(timelist, noonIndex)
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

    def self.nodeset_to_timelist(nodeset, search='td')
        #nodeset.search('td').collect { |x| x.inner_text.strip }
        nodeset.search(search).collect { |x| x.inner_text.strip }
    end

    def self.remove_bad_trains(train)
        train[:time].eql? '-' or time_greater_than?(Time.parse(train[:time]), Time.now)
    end

    def self.time_greater_than?(time1, time2)
        conv1 = Time.at(time1.hour * 60 * 60 + time1.min * 60 + time1.sec)
        conv2 = Time.at(time2.hour * 60 * 60 + time2.min * 60 + time2.sec)
        
        return conv1 < conv2
    end

    def self.filter_passed_trains(train_data)
        train_data.delete_if do |x|
            remove_bad_trains x
        end
    end

    def self.parse_caltrain_table(data, period)
        doc = Nokogiri::HTML(data)
        tables = doc.search('td#right table')
        if period == 'weekday'
            data = 
            {
                :northbound => tables[1],
                :southbound => tables[2]
            }
        else
            data = 
            {
                :northbound => tables[0],
                :southbound => tables[2]
            }

        end
    end

    def self.cache_train_schedule(period)
        table = cache_train_schedule_and_return(period)
        data = 
        {
            :status => nil
        }
    end

    def self.cache_train_schedule_and_return(period)
        table = get_caltrain_table period
        if File.exists?("/var/tmp/caltrainweekday.out")
            File.delete("/var/tmp/caltrainweekday.out")
        end
        if File.exists?("/var/tmp/caltrainweekend.out")
            File.delete("/var/tmp/caltrainweekend.out")
        end
        File.open("/var/tmp/caltrain#{period}.out", 'w') { |f| f.write(table) }
        return table
    end

    def self.getPeriod()
        if [1..5].include? Time.now.wday
            period = 'weekday'
        else
            period = 'weekend'
        end
    end

    def self.get_next_trains(num, stop)
        table = nil
        period = getPeriod
        if File.exists?("/var/tmp/caltrain#{period}.out") && ((Time.now - File.mtime("/var/tmp/caltrain#{period}.out") < (24 * 60 * 60)))
            table = File.read("/var/tmp/caltrain#{period}.out")
        else
            table = cache_train_schedule_and_return(period)
        end
        table = parse_caltrain_table(table, period)
        train_data = extract_stop(table, stop, period)

        data =
        {
            :northbound => filter_passed_trains(train_data[:northbound])[0..(num - 1)],
            :southbound => filter_passed_trains(train_data[:southbound])[0..(num - 1)]
        }
        return data
    end

    def self.get_next_trains_for_direction(num, stop, direction)
        data = get_next_trains(num, stop)
        train_status =
        {
            :status => data[direction.to_sym]
        }
    end
end

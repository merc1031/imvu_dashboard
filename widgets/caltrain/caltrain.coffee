class Dashing.Caltrain extends Dashing.Widget
    
    ready: ->
        @onData Dashing.lastEvents[@id]

    onData: (data) ->
        $(@node).find('.northbound ul').empty()
        $(@node).find('.southbound ul').empty()
        if data
            @appendTitle 'northbound'
            @updateStatus 'northbound', key, d for key, d of data.northbound
            @appendTitle 'southbound'
            @updateStatus 'southbound', key, d for key, d of data.southbound
            
    updateStatus: (direction, key, data) ->
        @appendNew direction, key
        
        $elem = $(@node).find('.' + direction + ' .status_' + key)
        $elem.find('.type h2').text(data.type)
        $elem.find('.time h2').text(data.time)
        $elem.find('.number h2').text(data.number)

    appendNew: (direction, key) ->
        $elem = $(@node).find('.template li').clone()
        $elem.addClass('status_' + key)
        $(@node).find('.' + direction + ' ul').append($elem)


    appendTitle: (direction) ->
        $elem = $(@node).find('.section_template li').clone()
        $elem.find('.title h2').text(direction[0].toUpperCase() + direction[1..-1].toLowerCase())
        $(@node).find('.' + direction + ' ul').append($elem)

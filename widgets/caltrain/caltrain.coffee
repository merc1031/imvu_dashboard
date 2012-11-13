class Dashing.Caltrain extends Dashing.Widget
    
    ready: ->
        @onData Dashing.lastEvents[@id]

    onData: (data) ->
        $(@node).find('.northbound ul').empty()
        $(@node).find('.southbound ul').empty()
        if data
            @updateStatus '.northbound', key, d for key, d of data.northbound
            @updateStatus '.southbound', key, d for key, d of data.southbound
            
    updateStatus: (direction, key, data) ->
        @appendNew direction, key
        
        $elem = $(@node).find(direction + ' .status_' + key)
        $elem.find('.type h2').text(data.type)
        $elem.find('.time h2').text(data.time)
        $elem.find('.number h2').text(data.number)

    appendNew: (direction, key) ->
        $elem = $(@node).find('.template li').clone()
        $elem.addClass('status_' + key)
        $(@node).find(direction + ' ul').append($elem)

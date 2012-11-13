class Dashing.Caltrain extends Dashing.Widget
    
    ready: ->
        @onData Dashing.lastEvents[@id]

    onData: (data) ->
        $(@node).find('.northbound').empty()
        $(@node).find('.southbound').empty()
        if data
            @updateStatus '.northbound', key, d for key, d of data.northbound
            @updateStatus '.southbound', key, d for key, d of data.southbound
            
    updateStatus: (direction, key, data) ->
        @appendNew direction, key
        
        $elem = $(@node).find(direction + ' .status_' + key)
        $elem.find('.type').text(data.type)
        $elem.find('.time').text(data.time)
        $elem.find('.number').text(data.number)

    appendNew: (direction, key) ->
        $elem = $(@node).find('.template li').clone()
        $elem.addClass('status_' + key)
        $(@node).find(direction).append($elem)

class Dashing.Caltrain extends Dashing.Widget
    
    ready: ->
        @onData Dashing.lastEvents[@id]

    onData: (data) ->
        $(@node).find('.direction ul').empty()
        if data
            @appendTitle()
            @updateStatus key, d for key, d of data.status
            
    updateStatus: (key, data) ->
        @appendNew key
        
        $elem = $(@node).find('.direction .status_' + key)
        $elem.find('.type h2').text(data.type)
        $elem.find('.time h2').text(data.time)
        $elem.find('.number h2').text(data.number)

    appendNew: (key) ->
        $elem = $(@node).find('.template li').clone()
        $elem.addClass('status_' + key)
        $(@node).find('.direction ul').append($elem)


    appendTitle: () ->
        $elem = $(@node).find('.section_template li').clone()
        $(@node).find('.direction ul').append($elem)

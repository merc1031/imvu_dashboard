class Dashing.Push extends Dashing.Widget

    in_progress = '#eb9c3c'
    failure     = '#dc5945'
    success     = '#96bf48'

    ready: ->
        @onData Dashing.lastEvents[@id]

    onData: (data) ->
        if data.statuses
            @updateStatus key, d for key, d of data.statuses

    updateStatus: (key, data) ->
        status_key = '.status_' + key
        if $(@node).find(status_key).length == 0
            @appendNew key, data
        $elem = $(@node).find(status_key)
        $elem.find('.type').text(key)
        $elem.find('.current h2').text(data.rev_in_production)
        $elem.find('.rising h2').text(data.rev)
        $elem.find('.user h2').text(data.user)
        $elem.find('.time h2').text(data.start)

        $elem.find('.rising').toggle(data.status != 1)
        if data.status < 0
            $elem.find('div').css('background-color', in_progress)
        else if data.status == 0
            $elem.find('div').css('background-color', failure)
        else
            $elem.find('div').css('background-color', success)

    appendNew: (key) ->
        $elem = $(@node).find('.template li').clone()
        $elem.addClass('status_' + key)
        $(@node).find('.push_types').append($elem)

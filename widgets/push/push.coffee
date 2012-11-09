class Dashing.Push extends Dashing.Widget

    onData: (data) ->
        if data.statuses
            @updateStatus key, d for key, d of data.statuses

    updateStatus: (key, data) ->
        status_key = '.status_' + key
        if $(@node).find(status_key).length == 0
            @appendNew key, data
        $elem = $(@node).find(status_key)
        $elem.find('.type').text(key)
        $elem.find('.current h2').text('todo')
        $elem.find('.rising h2').text(data.rev)
        $elem.find('.user h2').text(data.user)
        $elem.find('.time h2').text(data.start)

    appendNew: (key) ->
        $elem = $(@node).find('.template li').clone()
        $elem.addClass('status_' + key)
        $(@node).find('.push_types').append($elem)

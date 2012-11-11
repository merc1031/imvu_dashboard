class Dashing.Buildbot extends Dashing.Widget

    success   = '#96bf48'
    building  = '#eb9c3c'
    failure   = '#dc5945'
    exception = '#9c4274'

    current_build = 0

    onData: (data) ->
        if data.state
            @updateQueue data.queue
            @updateColor $(@node), data.state
            @updateColor $(@node).find('.previous'), data.last_state

    updateCurrent: (data) ->
        if current_build != data.revisions[0].rev
            $(@node).find('.current').append('<span><h2>' + data.revisions[0].user + ', ' + data.revisions[0].rev + '</h2></span>')

    updateQueue: (num) ->
        $(@node).find('.num_queued').text(num)

    updateColor: ($target, state) ->
        switch state
            when 'idle' then @setColor $target, success
            when 'building' then @setColor $target, building
            when 'failure' then @setColor $target, failure
            when 'exception' then @setColor $target, exception

    setColor: ($target, color) ->
        $target.css('background-color', color)

class Dashing.Buildbot extends Dashing.Widget

    success   = '#96bf48'
    building  = '#eb9c3c'
    failure   = '#dc5945'
    exception = '#9c4274'

    onData: (data) ->
        if data.state
            @updateColor data.state

    updateColor: (state) ->
        switch state
            when 'idle' then @setColor success
            when 'building' then @setColor building
            when 'failure' then @setColor failure
            when 'exception' then @setColor exception

    setColor: (color) ->
        $(@node).css('background-color', color)

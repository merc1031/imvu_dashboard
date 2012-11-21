class Dashing.Buildbot extends Dashing.Widget

    currentBuild: 0
    currentState: 'unknown'

    ready: ->
        @currentBuild = 0
        @onData Dashing.lastEvents[@id]

    onData: (data) ->
        if data && data.current.state
            @updateQueue data.current.queue
            if @shouldUpdate data.current
                @updateCurrent data.current
                @updatePrevious data.previous

    shouldUpdate: (revision) ->
        @isDifferentRevision(revision) || @isDifferentState(revision.state)

    isDifferentRevision: (revision) ->
        revision.revisions.length > 0 && @currentBuild != revision.revisions[0].rev

    isDifferentState: (state) ->
        @currentState != state

    updateCurrent: (data) ->
        @updateColor $(@node), data.state
        @populateRevisions data.revisions
        @currentBuild = data.revisions[0].rev
        @currentState = data.state

    populateRevisions: (revisions) ->
        $elem = $(@node).find('.current .revisions')
        $elem.empty()
        console.log revisions
        for revision in revisions
            $elem.append('<h2>' + "#{revision.rev}, #{revision.user}" + '</h2>')

    populateTime: (data) ->
        $elem = $(@node).find('.current .time')

    updatePrevious: (data) ->
        @updateColor $(@node).find('.previous .cell .container'), data.state
        $(@node).find('.build').text(@formatPrevious(data))

    formatPrevious: (data) ->
        formatted = ''
        numRevisions = data.revisions.length
        loopBound = Math.min(3, numRevisions) - 1
        for i in [0..loopBound] by 1
            formatted += data.revisions[i].user
            if i < loopBound
                formatted += ', '

        if numRevisions > 3
            formatted += " and #{numRevisions} more"
        formatted += " at #{data.end}"

    updateQueue: (num) ->
        $(@node).find('.num_queued').text(num)

    updateColor: ($target, state) ->
        switch state
            when 'idle' then @setColor $target, 'success'
            when 'building' then @setColor $target, 'building'
            when 'failure' then @setColor $target, 'failure'
            when 'exception' then @setColor $target, 'exception'

    setColor: ($target, cssClass) ->
        $target.removeClass('success').removeClass('building').removeClass('failure').removeClass('exception')
        $target.addClass(cssClass)

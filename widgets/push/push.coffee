class Dashing.Push extends Dashing.Widget

    # Pick colors from here:
    #   https://kuler.adobe.com/#themeID/2123634
    success:   '#007215'
    building:  '#F2BC79'
    failure:   '#BF1B39'
    exception: '#730240'

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
        @updateTime $elem, data

        $elem.find('.rising').toggle(data.status != 1)
        if data.status < 0
            @setColor $elem.find('div'), 'building'
        else if data.status == 0
            @setColor $elem.find('div'), 'failure'
        else
            @setColor $elem.find('div'), 'success'

    appendNew: (key) ->
        $elem = $(@node).find('.template li').clone()
        $elem.addClass('status_' + key)
        $(@node).find('.push_types').append($elem)

    updateTime: ($elem, data) ->
        if data.end
            $elem.find('.time h1').text('Finished')
            $elem.find('.time h2').text(data.end)
        else
            $elem.find('.time h1').text('Started')
            $elem.find('.time h2').text(data.start)

    setColor: ($target, cssClass) ->
        $target.removeClass('success').removeClass('building').removeClass('failure').removeClass('exception')
        $target.addClass(cssClass)

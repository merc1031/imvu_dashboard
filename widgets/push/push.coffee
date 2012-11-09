class Dashing.Push extends Dashing.Widget

    onData: (data) ->
        if data.statuses
            @updateStatus key, d for key, d of data.statuses

    updateStatus: (key, data) ->
        status_key = '.status_' + key
        if $(@node).find(status_key).length == 0
            @appendNew key, data
        $(@node).find(status_key).text(data.user)

    appendNew: (key, data) ->
        $(@node).find('.push_types').append('<li><span><div class="status_' + key + '"></div></span></li>')



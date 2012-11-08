class Dashing.Push extends Dashing.Widget

    updateStatus: (key, data) ->
        status_key = '.status_' + key
        if $(@node).find(status_key).length == 0
            $(@node).append('<h2 class="status_' + key + '"></h2>')
        $(@node).find(status_key).text(data.user)

    onData: (data) ->
        if data.statuses
            @updateStatus key, d for key, d of data.statuses


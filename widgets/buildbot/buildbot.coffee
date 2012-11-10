class Dashing.Buildbot extends Dashing.Widget
    ready: ->

    onData: (data) ->
        @updateStatus data.status

    updateStatus: (status) ->
        @set('failed', status.failed)
        @set('success', status.success)
        @set('warnings', status.warnings)
        @set('skipped', status.skipped)
        @set('exception', status.exception)
        @set('retry', status.retry)

require_relative '../lib/buildbot'

SCHEDULER.every '20s', :first_in => 0 do |job|
  send_event('web_buildbot', Buildbot.get_build_data('webbuildbot'))
  send_event('web_hypo', Buildbot.get_build_data('hypothesisbuildbot:8010'))
  send_event('client_buildbot', Buildbot.get_build_data('clientbuildbot'))
  send_event('client_hypo', Buildbot.get_build_data('clienthypobb:8010'))
end

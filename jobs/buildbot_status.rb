require_relative '../lib/buildbot'

SCHEDULER.every '20s', :first_in => 0 do |job|
  send_event('web_buildbot', Buildbot.get_build_data('webbuildbot'))
  send_event('web_hypo', Buildbot.get_build_data('hypothesisbuildbot.corp.imvu.com:8010'))
end

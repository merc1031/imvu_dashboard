require 'spec_helper'

# this is overkill, but I'm using it to warm back up on rspec

describe Buildbot do
    describe '#get_build' do
        it 'should return nil for invalid root url' do
            FakeWeb.register_uri(:get, %r|http://herpderp/.*|, :status => ["404", "Not Found"])
            Buildbot.get_build('herpderp', -1).should be_nil
        end
    end

    describe '#get_build_data' do
        it 'should return the current and previous build data'
    end

    describe '#extract_times' do
        it 'should format the times as HH:MM:SS'
        it 'should not process and invalid time'
    end
end

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
        it 'should not process an invalid time'
    end

    describe '#extract_state' do
        it 'should detect failed state' do
            build_data = { 'text' => ['derp', 'failed'] }
            aggregator_data = { 'state' => 'idle' }
            Buildbot.extract_state(build_data, aggregator_data).should eq('failure')
        end

        it 'should detect excepton state' do
            build_data = { 'text' => ['derp', 'exception'] }
            aggregator_data = { 'state' => 'idle' }
            Buildbot.extract_state(build_data, aggregator_data).should eq('exception')
        end

        it 'should detect building state' do
            build_data = { 'text' => ['derp'] }
            aggregator_data = { 'state' => 'building' }
            Buildbot.extract_state(build_data, aggregator_data).should eq('building')
        end

        it 'should default to idle' do
            build_data = { 'text' => ['derp'] }
            aggregator_data = {}
            Buildbot.extract_state(build_data, aggregator_data).should eq('idle')

            build_data = { 'text' => ['derp'] }
            aggregator_data = nil
            Buildbot.extract_state(build_data, aggregator_data).should eq('idle')
        end
    end
end

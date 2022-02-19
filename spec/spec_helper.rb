if ENV['RCOV']
  require 'simplecov'
  SimpleCov.start
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'hawk'
require 'pry'
require 'webmock/rspec'
require 'support/dalli_client_mock'

WebMock.disable_net_connect!

Hawk::HTTP::Instrumentation.suppress_verbose_output true

RSpec.configure do |config|
  config.before do
    allow(Dalli::Client).to receive(:new).and_return DalliClientMock.new
  end
end

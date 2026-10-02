if ENV['RCOV'] || ENV['COVERAGE']
  require 'simplecov'

  SimpleCov.start do
    add_filter '/spec/'

    track_files 'lib/**/*.rb'
  end
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

# Matches keys memcached accepts verbatim: ASCII, no whitespace, no control
# characters and at most 250 bytes long. The meta protocol used by Dalli 5
# rejects whitespace and non-ASCII keys, and Dalli works around it by
# base64-encoding the key, which inflates it by a third and can push it past the
# 250 byte limit memcached enforces on keys, making the server reply
# CLIENT_ERROR. Control characters are not base64-encoded by Dalli, so they
# reach memcached verbatim and are rejected there.
RSpec::Matchers.define :a_memcached_safe_key do
  match do |key|
    key.is_a?(String) && key.ascii_only? && !key.match?(/[[:cntrl:]\s]/) && key.bytesize <= 250
  end

  failure_message do |key|
    return "expected a memcached-safe key, got #{key.inspect}" unless key.is_a?(String)

    "expected a memcached-safe key, got #{key.inspect} (ascii_only: #{key.ascii_only?}, " \
      "unsafe characters: #{key.match?(/[[:cntrl:]\s]/)}, bytesize: #{key.bytesize})"
  end
end

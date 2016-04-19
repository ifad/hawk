$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'hawk'
require 'byebug'
require 'webmock/rspec'

WebMock.disable_net_connect!

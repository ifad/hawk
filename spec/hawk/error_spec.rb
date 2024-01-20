# frozen_string_literal: true

require 'spec_helper'

class Failure < Hawk::Model::Base
  url 'https://example.org/'
  client_name 'Foobar'
end

RSpec.describe Hawk::Error do
  it 'raises an exception when the response is 0' do
    stub_request(:GET, 'https://example.org/failures/0')
      .with(headers: { 'User-Agent' => 'Foobar' })
      .to_return(status: 0, body: 'Not found', headers: {})

    expect { Failure.find(0) }.to raise_error(described_class::Empty)
  end

  it 'raises an exception when the request is bad' do
    stub_request(:GET, 'https://example.org/failures/400')
      .with(headers: { 'User-Agent' => 'Foobar' })
      .to_return(status: 400, body: 'Not found', headers: {})

    expect { Failure.find(400) }.to raise_error(described_class::BadRequest)
  end

  it 'raises an exception when the request is forbidden' do
    stub_request(:GET, 'https://example.org/failures/403')
      .with(headers: { 'User-Agent' => 'Foobar' })
      .to_return(status: 403, body: 'Not found', headers: {})

    expect { Failure.find(403) }.to raise_error(described_class::Forbidden)
  end

  it 'raises an exception when the record is missing' do
    stub_request(:GET, 'https://example.org/failures/404')
      .with(headers: { 'User-Agent' => 'Foobar' })
      .to_return(status: 404, body: 'Not found', headers: {})

    expect { Failure.find(404) }.to raise_error(described_class::NotFound)
  end

  it 'raises an exception when the server returns an HTTP 500' do
    stub_request(:GET, 'https://example.org/failures/500')
      .with(headers: { 'User-Agent' => 'Foobar' })
      .to_return(status: 500, body: ':(', headers: {})

    expect { Failure.find(500) }.to raise_error(described_class::InternalServerError)
  end

  it 'raises an exception when the server returns unexpected HTTP codes' do
    stub_request(:GET, 'https://example.org/failures/666')
      .with(headers: { 'User-Agent' => 'Foobar' })
      .to_return(status: 666, body: '{}', headers: {})

    expect { Failure.find(666) }.to raise_error(described_class)
  end

  it 'raises an exception when the server times out' do
    stub_request(:GET, 'https://example.org/failures/123')
      .with(headers: { 'User-Agent' => 'Foobar' })
      .to_timeout

    expect { Failure.find(123) }.to raise_error(described_class::Timeout)
  end
end

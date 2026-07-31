# frozen_string_literal: true

require 'spec_helper'

class CachedResource < Hawk::Model::Base
  url 'https://example.org/'
  client_name 'Foobar'

  http_options cache: { server: 'localhost:11211' }

  schema do
    integer :id
    string :name
  end
end

RSpec.describe Hawk::HTTP::Caching do
  let(:cache) { CachedResource.connection.instance_variable_get(:@_cache) }

  # Parameters whose serialized descriptor contains whitespace and is long
  # enough that, were it used as the key verbatim, base64-encoding it for the
  # memcached meta protocol would push it past the 250 byte key limit and make
  # the server reply CLIENT_ERROR.
  let(:params) { { tags: '/nodes/country/AFG', note: 'Woody Allen ' * 12 } }

  before do
    allow(cache).to receive(:get).and_return(nil)
    allow(cache).to receive(:set)

    stub_request(:GET, 'https://example.org/cached_resources')
      .with(query: hash_including({}))
      .to_return(status: 200, body: [].to_json)
  end

  it 'is enabled' do
    expect(CachedResource.connection).to be_cache_configured
  end

  context 'with non-ASCII parameters' do
    let(:params) { { name: 'Amélie Poulain' } }

    it 'looks the response up with a memcached-safe key' do
      CachedResource.where(params).to_a

      expect(cache).to have_received(:get).with(a_memcached_safe_key)
    end
  end

  it 'looks the response up with a memcached-safe key' do
    CachedResource.where(params).to_a

    expect(cache).to have_received(:get).with(a_memcached_safe_key)
  end

  it 'stores the response under a memcached-safe key' do
    CachedResource.where(params).to_a

    expect(cache).to have_received(:set).with(a_memcached_safe_key, anything, anything)
  end

  it 'derives the same key for the same request' do
    2.times { CachedResource.where(params).to_a }

    expect(requested_keys.uniq.size).to eq(1)
  end

  it 'derives different keys for different requests' do
    CachedResource.where(params).to_a
    CachedResource.where(params.merge(tags: '/nodes/country/ITA')).to_a

    expect(requested_keys.uniq.size).to eq(2)
  end

  private

  def requested_keys
    keys = []
    expect(cache).to have_received(:get) { |key| keys << key }.at_least(:once)
    keys
  end
end

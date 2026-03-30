# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Hawk::HTTP::CacheAdapters do
  describe Hawk::HTTP::CacheAdapters::DalliAdapter do
    subject(:adapter) { described_class.new(server, options) }

    let(:server) { 'localhost:11211' }
    let(:options) { { namespace: 'test', compress: true } }
    let(:dalli_client) { instance_spy(Dalli::Client) }

    before do
      allow(Dalli::Client).to receive(:new).with(server, options).and_return(dalli_client)
    end

    describe '#get' do
      it 'delegates to Dalli client' do
        allow(dalli_client).to receive(:get).with('key1').and_return('value1')
        expect(adapter.get('key1')).to eq('value1')
        expect(dalli_client).to have_received(:get).with('key1')
      end
    end

    describe '#set' do
      it 'delegates to Dalli client with TTL' do
        allow(dalli_client).to receive(:set).with('key1', 'value1', 60)
        adapter.set('key1', 'value1', 60)
        expect(dalli_client).to have_received(:set).with('key1', 'value1', 60)
      end
    end

    describe '#delete' do
      it 'delegates to Dalli client' do
        allow(dalli_client).to receive(:delete).with('key1')
        adapter.delete('key1')
        expect(dalli_client).to have_received(:delete).with('key1')
      end
    end

    describe '#version' do
      it 'fetches version from Dalli client' do
        version_hash = { server => '1.6.0' }
        allow(dalli_client).to receive(:version).and_return(version_hash)
        expect(adapter.version).to eq('1.6.0')
      end

      it 'returns nil when version fetch fails' do
        allow(dalli_client).to receive(:version).and_raise(StandardError)
        expect(adapter.version).to be_nil
      end
    end
  end

  describe Hawk::HTTP::CacheAdapters::RedisAdapter do
    subject(:adapter) { described_class.new(server, options) }

    let(:server) { 'redis://localhost:6379' }
    let(:options) { { namespace: 'hawk' } }
    let(:redis_client) { instance_spy(Redis) }
    let(:redis_class) do
      Class.new do
        def self.new(*_args, **_kwargs); end
      end
    end

    before do
      # Stub the Redis gem loading by stubbing the private method
      allow_any_instance_of(described_class).to receive(:load_redis_library) # rubocop:disable RSpec/AnyInstance
      stub_const('Redis', redis_class)
      allow(Redis).to receive(:new).and_return(redis_client)
    end

    describe '#initialize with different server formats' do
      it 'creates Redis client with redis:// URL' do
        allow(Redis).to receive(:new).with(url: 'redis://localhost:6379').and_return(redis_client)
        described_class.new('redis://localhost:6379', options)
        expect(Redis).to have_received(:new).with(url: 'redis://localhost:6379')
      end

      it 'creates Redis client with rediss:// URL' do
        allow(Redis).to receive(:new).with(url: 'rediss://localhost:6379').and_return(redis_client)
        described_class.new('rediss://localhost:6379', options)
        expect(Redis).to have_received(:new).with(url: 'rediss://localhost:6379')
      end

      it 'creates Redis client with host:port format' do
        allow(Redis).to receive(:new).with(host: 'localhost', port: 6380).and_return(redis_client)
        described_class.new('localhost:6380', { namespace: 'test' })
        expect(Redis).to have_received(:new).with(host: 'localhost', port: 6380)
      end

      it 'creates Redis client with default port' do
        allow(Redis).to receive(:new).with(host: 'myredis', port: 6379).and_return(redis_client)
        described_class.new('myredis', { namespace: 'test' })
        expect(Redis).to have_received(:new).with(host: 'myredis', port: 6379)
      end
    end

    describe '#get' do
      it 'delegates to Redis client with namespaced key' do
        allow(redis_client).to receive(:get).with('hawk:key1').and_return('value1')
        expect(adapter.get('key1')).to eq('value1')
        expect(redis_client).to have_received(:get).with('hawk:key1')
      end
    end

    describe '#get without namespace' do
      let(:options) { {} }

      it 'uses key without namespace' do
        allow(redis_client).to receive(:get).with('key1').and_return('value1')
        expect(adapter.get('key1')).to eq('value1')
        expect(redis_client).to have_received(:get).with('key1')
      end
    end

    describe '#set' do
      it 'delegates to Redis client with namespaced key and TTL' do
        allow(redis_client).to receive(:set).with('hawk:key1', 'value1', ex: 60)
        adapter.set('key1', 'value1', 60)
        expect(redis_client).to have_received(:set).with('hawk:key1', 'value1', ex: 60)
      end

      it 'sets without TTL when ttl is nil' do
        allow(redis_client).to receive(:set).with('hawk:key1', 'value1')
        adapter.set('key1', 'value1', nil)
        expect(redis_client).to have_received(:set).with('hawk:key1', 'value1')
      end

      it 'sets without TTL when ttl is 0' do
        allow(redis_client).to receive(:set).with('hawk:key1', 'value1')
        adapter.set('key1', 'value1', 0)
        expect(redis_client).to have_received(:set).with('hawk:key1', 'value1')
      end
    end

    describe '#set without namespace' do
      let(:options) { {} }

      it 'uses key without namespace' do
        allow(redis_client).to receive(:set).with('key1', 'value1', ex: 60)
        adapter.set('key1', 'value1', 60)
        expect(redis_client).to have_received(:set).with('key1', 'value1', ex: 60)
      end
    end

    describe '#delete' do
      it 'delegates to Redis client with namespaced key' do
        allow(redis_client).to receive(:del).with('hawk:key1')
        adapter.delete('key1')
        expect(redis_client).to have_received(:del).with('hawk:key1')
      end
    end

    describe '#delete without namespace' do
      let(:options) { {} }

      it 'uses key without namespace' do
        allow(redis_client).to receive(:del).with('key1')
        adapter.delete('key1')
        expect(redis_client).to have_received(:del).with('key1')
      end
    end

    describe '#version' do
      it 'fetches version from Redis INFO' do
        allow(redis_client).to receive(:info).and_return({ 'redis_version' => '6.2.0' })
        expect(adapter.version).to eq('6.2.0')
      end

      it 'fetches version from nested Server hash' do
        allow(redis_client).to receive(:info).and_return({ 'Server' => { 'redis_version' => '7.0.0' } })
        expect(adapter.version).to eq('7.0.0')
      end

      it 'returns nil when version fetch fails' do
        allow(redis_client).to receive(:info).and_raise(StandardError)
        expect(adapter.version).to be_nil
      end
    end
  end
end

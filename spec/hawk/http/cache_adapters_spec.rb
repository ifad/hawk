# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Hawk::HTTP::CacheAdapters do
  describe Hawk::HTTP::CacheAdapters::DalliAdapter do
    let(:server) { 'localhost:11211' }
    let(:options) { { namespace: 'test', compress: true } }
    let(:dalli_client) { instance_double(Dalli::Client) }
    let(:adapter) { described_class.new(server, options) }

    before do
      allow(Dalli::Client).to receive(:new).with(server, options).and_return(dalli_client)
    end

    describe '#get' do
      it 'delegates to Dalli client' do
        expect(dalli_client).to receive(:get).with('key1').and_return('value1')
        expect(adapter.get('key1')).to eq('value1')
      end
    end

    describe '#set' do
      it 'delegates to Dalli client with TTL' do
        expect(dalli_client).to receive(:set).with('key1', 'value1', 60)
        adapter.set('key1', 'value1', 60)
      end
    end

    describe '#delete' do
      it 'delegates to Dalli client' do
        expect(dalli_client).to receive(:delete).with('key1')
        adapter.delete('key1')
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
    let(:server) { 'redis://localhost:6379' }
    let(:adapter) { described_class.new(server, options) }
    let(:options) { { namespace: 'hawk' } }
    let(:redis_client) { instance_double('Redis') }

    before do
      # Stub the Redis gem loading
      allow_any_instance_of(described_class).to receive(:load_redis_library)

      # Create a mock Redis class that accepts new with any arguments
      redis_class = Class.new do
        def self.new(*_args, **_kwargs)
          # This will be stubbed in individual tests
        end
      end
      stub_const('Redis', redis_class)
      allow(Redis).to receive(:new).and_return(redis_client)
    end

    describe '#initialize' do
      context 'with redis:// URL' do
        it 'creates Redis client with URL' do
          expect(Redis).to receive(:new).with(url: 'redis://localhost:6379')
          described_class.new('redis://localhost:6379', options)
        end
      end

      context 'with rediss:// URL' do
        it 'creates Redis client with URL' do
          expect(Redis).to receive(:new).with(url: 'rediss://localhost:6379')
          described_class.new('rediss://localhost:6379', options)
        end
      end

      context 'with host:port format' do
        it 'creates Redis client with host and port' do
          expect(Redis).to receive(:new).with(host: 'localhost', port: 6380)
          described_class.new('localhost:6380', { namespace: 'test' })
        end
      end

      context 'with just host' do
        it 'creates Redis client with default port' do
          expect(Redis).to receive(:new).with(host: 'myredis', port: 6379)
          described_class.new('myredis', { namespace: 'test' })
        end
      end
    end

    describe '#get' do
      it 'delegates to Redis client with namespaced key' do
        expect(redis_client).to receive(:get).with('hawk:key1').and_return('value1')
        expect(adapter.get('key1')).to eq('value1')
      end

      context 'without namespace' do
        let(:options) { {} }

        it 'uses key without namespace' do
          expect(redis_client).to receive(:get).with('key1').and_return('value1')
          expect(adapter.get('key1')).to eq('value1')
        end
      end
    end

    describe '#set' do
      it 'delegates to Redis client with namespaced key and TTL' do
        expect(redis_client).to receive(:set).with('hawk:key1', 'value1', ex: 60)
        adapter.set('key1', 'value1', 60)
      end

      it 'sets without TTL when ttl is nil' do
        expect(redis_client).to receive(:set).with('hawk:key1', 'value1')
        adapter.set('key1', 'value1', nil)
      end

      it 'sets without TTL when ttl is 0' do
        expect(redis_client).to receive(:set).with('hawk:key1', 'value1')
        adapter.set('key1', 'value1', 0)
      end

      context 'without namespace' do
        let(:options) { {} }

        it 'uses key without namespace' do
          expect(redis_client).to receive(:set).with('key1', 'value1', ex: 60)
          adapter.set('key1', 'value1', 60)
        end
      end
    end

    describe '#delete' do
      it 'delegates to Redis client with namespaced key' do
        expect(redis_client).to receive(:del).with('hawk:key1')
        adapter.delete('key1')
      end

      context 'without namespace' do
        let(:options) { {} }

        it 'uses key without namespace' do
          expect(redis_client).to receive(:del).with('key1')
          adapter.delete('key1')
        end
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

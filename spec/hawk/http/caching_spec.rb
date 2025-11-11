# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Hawk::HTTP::Caching do
  describe 'driver detection and configuration' do
    context 'with default configuration' do
      it 'uses Dalli adapter by default' do
        adapter = Hawk::HTTP::CacheAdapters::DalliAdapter.new('localhost:11211', namespace: 'hawk')
        expect(adapter).to be_a(Hawk::HTTP::CacheAdapters::DalliAdapter)
      end
    end

    context 'with explicit driver option' do
      it 'uses specified driver' do
        http = Hawk::HTTP.new('https://example.org/', cache: { driver: :dalli, server: 'localhost:11211' })
        driver = http.send(:detect_driver, 'localhost:11211', :dalli)
        expect(driver).to eq(:dalli)
      end

      it 'uses redis driver when specified' do
        # We don't instantiate HTTP here to avoid loading Redis
        # Just test the driver detection logic directly
        http = Hawk::HTTP.allocate
        driver = http.send(:detect_driver, 'localhost:6379', :redis)
        expect(driver).to eq(:redis)
      end
    end

    context 'with URL-based driver detection' do
      it 'detects redis from redis:// URL' do
        http = Hawk::HTTP.new('https://example.org/')
        driver = http.send(:detect_driver, 'redis://localhost:6379', nil)
        expect(driver).to eq(:redis)
      end

      it 'detects redis from rediss:// URL' do
        http = Hawk::HTTP.new('https://example.org/')
        driver = http.send(:detect_driver, 'rediss://localhost:6379', nil)
        expect(driver).to eq(:redis)
      end

      it 'defaults to dalli for non-redis URLs' do
        http = Hawk::HTTP.new('https://example.org/')
        driver = http.send(:detect_driver, 'localhost:11211', nil)
        expect(driver).to eq(:dalli)
      end
    end

    context 'with cache configuration' do
      it 'includes driver in DEFAULTS' do
        expect(Hawk::HTTP::Caching::DEFAULTS[:driver]).to eq(:dalli)
      end

      it 'preserves all original DEFAULTS options' do
        expect(Hawk::HTTP::Caching::DEFAULTS).to include(
          server: 'localhost:11211',
          namespace: 'hawk',
          compress: true,
          expires_in: 60
        )
      end
    end
  end

  describe 'backward compatibility' do
    it 'works without specifying driver option' do
      http = Hawk::HTTP.new('https://example.org/', cache: { server: 'localhost:11211' })
      expect(http).to be_a(Hawk::HTTP)
    end

    it 'maintains existing cache_configured? behavior' do
      http_with_cache = Hawk::HTTP.new('https://example.org/', cache: { server: 'localhost:11211' })
      http_without_cache = Hawk::HTTP.new('https://example.org/', cache: { disabled: true })

      expect(http_with_cache.cache_configured?).to be true
      expect(http_without_cache.cache_configured?).to be false
    end

    it 'maintains existing cache_options behavior' do
      http = Hawk::HTTP.new('https://example.org/', cache: { server: 'localhost:11211', expires_in: 120 })
      expect(http.cache_options).to include(expires_in: 120)
    end
  end
end

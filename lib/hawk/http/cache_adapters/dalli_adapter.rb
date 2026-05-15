# frozen_string_literal: true

module Hawk
  class HTTP
    module CacheAdapters
      # Adapter for Memcached via Dalli, preserving existing behavior.
      class DalliAdapter
        def initialize(server, options)
          @server = server
          @client = Dalli::Client.new(server, options)
        end

        def get(key)
          @client.get(key)
        end

        # For Dalli, the third parameter is TTL in seconds.
        def set(key, value, ttl)
          @client.set(key, value, ttl)
        end

        def delete(key)
          @client.delete(key)
        end

        def version
          @client.version.fetch(@server, nil)
        rescue StandardError
          nil
        end
      end
    end
  end
end

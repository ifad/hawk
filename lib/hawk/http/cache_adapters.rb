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

      # Adapter for Redis.
      # Note: requires the 'redis' gem in the host application.
      class RedisAdapter
        def initialize(server, options)
          load_redis_library

          @namespace = options[:namespace]
          @client    = build_client(server)
        end

        def get(key)
          @client.get(namespaced(key))
        end

        # TTL semantics: seconds, same as Dalli usage.
        def set(key, value, ttl)
          k = namespaced(key)
          if ttl&.to_i&.positive?
            @client.set(k, value, ex: ttl.to_i)
          else
            @client.set(k, value)
          end
        end

        def delete(key)
          @client.del(namespaced(key))
        end

        def version
          info = @client.info
          info['redis_version'] || (info.is_a?(Hash) && info.dig('Server', 'redis_version'))
        rescue StandardError
          nil
        end

        private

        def load_redis_library
          require 'redis' # lazy load; add `gem 'redis'` to your Gemfile to use
        end

        def namespaced(key)
          @namespace ? "#{@namespace}:#{key}" : key
        end

        def build_client(server)
          s = server.to_s
          if s.start_with?('redis://', 'rediss://')
            Redis.new(url: s)
          else
            host, port = s.split(':', 2)
            Redis.new(host: host || '127.0.0.1', port: (port || 6379).to_i)
          end
        end
      end
    end
  end
end

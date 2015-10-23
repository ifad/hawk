require 'dalli'

module Hawk
  class HTTP

    module Caching
      DEFAULTS = {
        server: 'localhost:11211',
        namespace: 'hawk',
        compress: true,
        expires_in: 60,
        serializer: MultiJson
      }

      def initialize(*)
        super

        options = defaults.delete(:cache) || {}
        initialize_cache(DEFAULTS.merge(options))
      end

      def inspect
        description = if cache_configured?
          "cache: ON #{@_cache_server} v#{@_cache_version}"
        else
          "cache: OFF"
        end

        super.sub(/>$/, ", #{description}>")
      end

      protected
        def caching(descriptor, &block)
          return block.call unless cache_configured?

          result = try_cache(descriptor, &block)

          if descriptor.key?(:invalidate)
            invalidate(descriptor)
          end

          return result
        end

      private
        def cache_key(descriptor)
          MultiJson.dump(descriptor)
        end

        def try_cache(descriptor, &block)
          return block.call unless descriptor[:method] == 'GET'

          key = cache_key(descriptor)

          cached = @_cache.get(key)
          if cached
            descriptor[:cached] = true
            cached
          else
            block.call.tap do |cacheable|
              #$stderr.puts "CACHE: store #{key}"
              @_cache.set(key, cacheable, descriptor[:ttl])
            end
          end
        end

        def invalidate(descriptor, &block)
          descriptor = descriptor.dup
          descriptor[:method] = 'GET'
          descriptor[:params] ||= {}

          paths = Array.wrap(descriptor.delete(:invalidate))

          paths.each do |path|
            descriptor[:url] = build_url(path)

            key = cache_key(descriptor)

            #$stderr.puts "CACHE: delete #{key}"
            @_cache.delete(key)
          end
        end

        def initialize_cache(options)
          server = options.delete(:server)
          return unless server

          client = Dalli::Client.new(server, options)

          if version = client.version.fetch(server, nil)
            @_cache = client
            @_cache_server = server
            @_cache_options = options
            @_cache_version = version
          else
            $stderr.puts "Hawk: can't connect to memcached server #{server}, caching disabled"
          end
        end

        def cache_configured?
          !@_cache.nil?
        end
    end

  end
end

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
        initialize_cache(DEFAULTS.deep_merge(options))
      end

      def inspect
        description = if cache_configured?
                        "cache: ON #{@_cache_server} v#{@_cache_version}"
                      else
                        "cache: OFF"
                      end

        super.sub(/>$/, ", #{description}>")
      end

      def cache_configured?
        !@_cache.nil?
      end

      def cache_options
        @_cache_options
      end

      protected

      def caching(descriptor, &block)
        return yield unless cache_configured?

        result = try_cache(descriptor, &block)

        if descriptor.key?(:invalidate)
          invalidate(descriptor)
        end

        result
      end

      private

      def cache_key(descriptor)
        MultiJson.dump(descriptor)
      end

      def try_cache(descriptor)
        return yield unless descriptor[:method] == 'GET'

        key = cache_key(descriptor)

        cached = @_cache.get(key)
        if cached
          descriptor[:cached] = true
          cached
        else
          ttl = descriptor[:expires_in] ||
                @_cache_options[:expires_in]

          yield.tap do |cacheable|
            # $stderr.puts "CACHE: store #{key} with ttl #{ttl}"
            @_cache.set(key, cacheable, ttl)
          end
        end
      end

      def invalidate(descriptor)
        descriptor = descriptor.dup
        descriptor[:method] = 'GET'
        descriptor[:params] ||= {}

        paths = Array.wrap(descriptor.delete(:invalidate))

        paths.each do |path|
          descriptor[:url] = build_url(path)

          key = cache_key(descriptor)

          # $stderr.puts "CACHE: delete #{key}"
          @_cache.delete(key)
        end
      end

      def initialize_cache(options)
        return if options[:disabled]

        unless options.key?(:server)
          raise Error::Configuration, "Cache server option is mandatory"
        end

        client, server, version = connect_cache(options)

        if client && server && version
          @_cache = client
          @_cache_server = server
          @_cache_version = version
          @_cache_options = options
        end
      end

      def connect_cache(options)
        static_options = options.dup
        static_options.delete(:expires_in)

        cache_servers[static_options] ||= begin
          server = options[:server]
          client = Dalli::Client.new(server, static_options)

          if version = client.version.fetch(server, nil)
            [client, server, version]
          else
            $stderr.puts "Hawk: can't connect to memcached server #{server}"
            nil
          end
        end
      end

      def cache_servers
        @@cache_servers ||= {}
      end
    end
  end
end

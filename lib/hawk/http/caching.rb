# frozen_string_literal: true

require 'digest'
require 'dalli'

module Hawk
  class HTTP
    ##
    # Provides Memcached-based caching for HTTP requests. Caches GET request
    # responses and supports cache invalidation for mutations.
    #
    # @example Configuring caching
    #   client = Hawk::HTTP.new("https://api.example.com/",
    #     cache: {
    #       server: 'localhost:11211',
    #       namespace: 'myapp',
    #       expires_in: 300
    #     }
    #   )
    #
    # @example Disabling caching
    #   client = Hawk::HTTP.new("https://api.example.com/",
    #     cache: { disabled: true }
    #   )
    #
    module Caching
      ##
      # Default cache configuration options.
      #
      # @return [Hash] default cache options
      DEFAULTS = {
        server: 'localhost:11211',
        namespace: 'hawk',
        compress: true,
        expires_in: 60,
        serializer: MultiJson
      }.freeze

      ##
      # Initializes the caching module with the given options.
      def initialize(*)
        super

        options = defaults.delete(:cache) || {}
        initialize_cache(DEFAULTS.deep_merge(options))
      end

      ##
      # Returns a string representation including cache status.
      #
      # @return [String] human-readable representation
      def inspect
        description = if cache_configured?
                        "cache: ON #{@_cache_server} v#{@_cache_version}"
                      else
                        'cache: OFF'
                      end

        super.sub(/>$/, ", #{description}>")
      end

      ##
      # Returns whether caching is configured and enabled.
      #
      # @return [Boolean] true if caching is enabled
      def cache_configured?
        !@_cache.nil?
      end

      ##
      # Returns the cache configuration options.
      #
      # @return [Hash] the cache options
      def cache_options
        @_cache_options
      end

      protected

      ##
      # Executes a block with caching support. Returns cached results for
      # GET requests and stores new results in the cache.
      #
      # @param descriptor [Hash] request descriptor with url, method, params
      # @yield block to execute if not cached
      # @return [Object] cached or fresh response
      def caching(descriptor, &block)
        return yield unless cache_configured?

        result = try_cache(descriptor, &block)

        if descriptor.key?(:invalidate)
          invalidate(descriptor)
        end

        result
      end

      private

      ##
      # Generates a cache key from the request descriptor.
      #
      # Memcached keys must be ASCII, free of whitespace and at most 250 bytes
      # long. Dalli's meta protocol works around the first two constraints by
      # base64-encoding the key, which inflates it by a third and can push it
      # past the length limit, at which point the server replies CLIENT_ERROR.
      # Digesting keeps the key valid whatever the url and params contain.
      #
      # @param descriptor [Hash] request descriptor
      # @return [String] the cache key
      def cache_key(descriptor)
        Digest::SHA256.hexdigest(MultiJson.dump(descriptor))
      end

      ##
      # Tries to fetch from cache or execute the block and cache the result.
      #
      # @param descriptor [Hash] request descriptor
      # @yield block to execute if not cached
      # @return [Object] cached or fresh response
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

      ##
      # Invalidates cache entries for the given descriptor.
      #
      # @param descriptor [Hash] request descriptor with :invalidate paths
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

      ##
      # Initializes the Memcached client connection.
      #
      # @param options [Hash] cache configuration options
      def initialize_cache(options)
        return if options[:disabled]

        unless options.key?(:server)
          raise Error::Configuration, 'Cache server option is mandatory'
        end

        client, server, version = connect_cache(options)

        if client && server && version
          @_cache = client
          @_cache_server = server
          @_cache_version = version
          @_cache_options = options
        end
      end

      ##
      # Establishes a connection to the Memcached server.
      #
      # @param options [Hash] cache configuration options
      # @return [Array(Dalli::Client, String, String), nil] client, server, version or nil
      def connect_cache(options)
        static_options = options.dup
        static_options.delete(:expires_in)

        cache_servers[static_options] ||= begin
          server = options[:server]
          client = Dalli::Client.new(server, static_options)

          if version = client.version.fetch(server, nil)
            [client, server, version]
          else
            warn "Hawk: can't connect to memcached server #{server}"
            nil
          end
        end
      end

      ##
      # Returns the cache servers registry.
      #
      # @return [Hash] cache server connections
      def cache_servers
        @@cache_servers ||= {}
      end
    end
  end
end

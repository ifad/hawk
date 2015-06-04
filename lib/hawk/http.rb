module Hawk

  require 'uri'
  require 'typhoeus'
  require 'multi_json'

  require 'hawk/http/caching'
  require 'hawk/http/instrumentation'

  ##
  # Represent an HTTP connector, to be linked to a {Model}.
  #
  class HTTP
    prepend Caching
    include Instrumentation

    DEFAULTS = {
      timeout:         2,
      connect_timeout: 1,
      # username:      nil,
      # password:      nil,
    }

    def initialize(base, options = {})
      @defaults = DEFAULTS.merge(options).freeze

      @base = URI.parse(base).tap do |url|
        unless %w( http https ).include? url.scheme
          raise Error::Configuration,
            "URL '#{url}' is not valid: only http and https schemes are supported"
        end

        url.path += '/' unless url.path =~ /\/$/
        url.freeze
      end
    end

    attr_reader :base, :defaults

    def inspect
      "#<#{self.class.name} to #{base}>"
    end

    def get(path, params = {})
      parse request(path, method: :get, params: params)
    end

    def post(path, params = {})
      parse request(path, method: :post, body: params)
    end

    protected
      def parse(body)
        MultiJson.load(body)
      end

      def request(path, options)
        url = base.merge(path.sub(/^\//, ''))

        descriptor = {url: url, params: options[:params], method: options[:method].to_s.upcase}
        instrument :request, descriptor do |descriptor|
          caching descriptor do
            options = typhoeus_defaults.merge(options_for_typhoeus(options))
            request = Typhoeus::Request.new(url, options)
            request.on_complete(&method(:response_handler))

            request.run.body
          end
        end
      end

    private
      def response_handler(response)
        return if response.success?

        req  = response.request
        url  = req.url
        meth = req.options.fetch(:method).to_s.upcase
        it   = [meth, url].join(' ')

        if response.timed_out?
          what, secs = if response.connect_time.zero? # Connect failed
            [ :connect, req.options[:connecttimeout] ]
          else
            [ :request, req.options[:timeout] ]
          end

          raise Error::Timeout, "#{it}: #{what} timed out after #{secs} seconds"
        end

        case response.response_code
        when 0
          raise Error::Empty, "#{it}: Empty response from server (#{response.status_message})"
        when 404
          raise Error::NotFound, "#{it} was not found"
        when 500
          raise Error::InternalServerError, "#{it}: Server error (#{response.body[0 .. 120]})"
        else
          raise Error, "#{it} failed with error #{response.code} (#{response.status_message})"
        end
      end

      def typhoeus_defaults
        @_typhoeus_defaults ||= options_for_typhoeus(defaults)
      end

      def options_for_typhoeus(hawk_options)
        hawk_options.inject({}) do |ret, (opt, val)|
          case opt
          when :request_timeout, :timeout
            ret[:timeout] = val.to_i

          when :connect_timeout
            ret[:connecttimeout] = val.to_i

          when :username        then
            unless hawk_options.key?(:password)
              raise Error::Configuration,
                "The 'username' option requires a corresponding 'password' option"
            end

            ret[:userpwd] = [val, hawk_options.fetch(:password)].join(':')
          else
            # Pass it along directly. Not pretty, not a consistent interface,
            # but it eases development for now. For sure it deserves a FIXME.
            #
            ret[opt] = val
          end

          ret
        end
      end
    end

end

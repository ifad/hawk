module Hawk

  require 'uri'
  require 'typhoeus'
  require 'multi_json'

  ##
  # Represent an HTTP connector, to be linked to a {Model}.
  #
  class HTTP
    DEFAULTS = {
      timeout:        2,
      connecttimeout: 2
    }

    def initialize(base, options = {})
      @defaults = DEFAULTS.merge(options)

      @base = URI.parse(base).tap do |url|
        unless %w( http https ).include? url.scheme
          raise Error::Configuration,
            "URL '#{url}' is not valid: only http and https schemes are supported"
        end

        url.path += '/' unless url.path =~ /\/$/
        url.freeze
      end
    end

    attr_reader :base

    def config
      @_config ||= OpenStruct.new(@defaults).freeze
    end

    def inspect
      "#<#{self.class.name} to #{base}>"
    end

    def get(path, params = {})
      parse request(path, method: :get, params: params)
    end

    def post(path, params = {})
      parse request(path, method: :post, params: params)
    end

    protected
      def request(path, options)
        url = base.merge(path.sub(/^\//, ''))

        request = Typhoeus::Request.new(url, @defaults.merge(options))
        request.on_complete(&method(:response_handler))

        request.run.response_body
      end

    private
      def response_handler(response)
        return if response.success?

        url  = response.request.url
        meth = response.request.options.fetch(:method).to_s.upcase
        req  = [meth, url].join(' ')

        if response.timed_out?
          raise Error::Timeout, "#{req}: timed out after #{config.timeout} seconds"
        end

        case response.response_code
        when 0
          raise Error::Empty, "#{req}: Empty response from server (#{response.status_message})"
        when 404
          raise Error::NotFound, "#{req} was not found"
        when 500
          raise Error::InternalServerError, "#{req}: Server error (#{response.body[0..120]})"
        else
          raise Error, "#{req} failed with error #{response.code} (#{response.status_message})"
        end
      end

      def parse(body)
        MultiJson.load(body)
      end
    end

end

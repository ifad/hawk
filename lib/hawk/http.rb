# frozen_string_literal: true

module Hawk
  require 'uri'
  require 'typhoeus'
  require 'multi_json'

  require_relative 'http/caching'
  require_relative 'http/instrumentation'

  ##
  # Represents an HTTP connector, to be linked to a {Model}. Handles all
  # HTTP communication with remote API endpoints, including request building,
  # response parsing, error handling, and optional caching via Memcached.
  #
  # @example Creating an HTTP client
  #   client = Hawk::HTTP.new("https://api.example.org/", timeout: 30)
  #   client.get("posts/1")
  #
  # @example Posting data
  #   client.post("posts", title: "Hello", body: "World")
  #
  # @see Hawk::Model::Connection
  class HTTP
    prepend Caching
    include Instrumentation

    ##
    # Default configuration options for HTTP requests.
    #
    # @return [Hash] default options with timeout, connect_timeout, and params_encoding
    DEFAULTS = {
      timeout: 2,
      connect_timeout: 1,
      params_encoding: :rack
      # username:      nil,
      # password:      nil,
    }.freeze

    ##
    # Valid URI schemes supported by Hawk.
    #
    # @return [Array<String>] list of supported schemes
    VALID_SCHEMES = %w[http https].freeze

    ##
    # Initializes a new HTTP client instance with the given base URL and options.
    #
    # @param base [String] the base URL for the HTTP client (must include a valid scheme)
    # @param options [Hash] optional configuration settings to override defaults
    # @option options [Integer] :timeout (2) maximum time in seconds to wait for a response
    # @option options [Integer] :connect_timeout (1) maximum time in seconds to wait for connection
    # @option options [Symbol] :params_encoding (:rack) encoding format for request parameters
    # @option options [String] :username username for basic authentication
    # @option options [String] :password password for basic authentication
    # @option options [Hash] :cache Memcached caching configuration
    #
    # @raise [Hawk::Error::Configuration] if the base URL has an invalid scheme
    #
    # @example
    #   client = Hawk::HTTP.new("https://api.example.org", timeout: 30)
    def initialize(base, options = {})
      @defaults = DEFAULTS.deep_merge(options)

      @base = URI.parse(base).tap do |url|
        unless VALID_SCHEMES.include? url.scheme
          raise Error::Configuration,
                "URL '#{url}' is not valid. Supported schemes: #{VALID_SCHEMES.join(', ')}"
        end

        url.path += '/' unless url.path&.end_with?('/')
        url.freeze
      end
    end

    ##
    # The base URL for this HTTP client.
    #
    # @return [URI] the base URL
    attr_reader :base, :defaults

    ##
    # Returns a string representation of the HTTP client.
    #
    # @return [String] a human-readable representation
    def inspect
      "#<#{self.class.name} to #{base}>"
    end

    ##
    # Performs a GET request and returns the parsed JSON response.
    #
    # @param path [String] the URL path to request
    # @param params [Hash] query parameters
    # @return [Object] parsed JSON response
    def get(path, params = {})
      parse raw_get(path, params)
    end

    ##
    # Performs a GET request and returns the raw response body.
    #
    # @param path [String] the URL path to request
    # @param params [Hash] query parameters
    # @return [String] raw response body
    def raw_get(path, params = {})
      request('GET', path, params)
    end

    ##
    # Performs a POST request and returns the parsed JSON response.
    #
    # @param path [String] the URL path to request
    # @param params [Hash] request body parameters
    # @return [Object] parsed JSON response
    def post(path, params = {})
      parse raw_post(path, params)
    end

    ##
    # Performs a POST request and returns the raw response body.
    #
    # @param path [String] the URL path to request
    # @param params [Hash] request body parameters
    # @return [String] raw response body
    def raw_post(path, params = {})
      request('POST', path, params)
    end

    ##
    # Performs a PUT request and returns the parsed JSON response.
    #
    # @param path [String] the URL path to request
    # @param params [Hash] request body parameters
    # @return [Object] parsed JSON response
    def put(path, params = {})
      parse raw_put(path, params)
    end

    ##
    # Performs a PUT request and returns the raw response body.
    #
    # @param path [String] the URL path to request
    # @param params [Hash] request body parameters
    # @return [String] raw response body
    def raw_put(path, params = {})
      request('PUT', path, params)
    end

    ##
    # Performs a PATCH request and returns the parsed JSON response.
    #
    # @param path [String] the URL path to request
    # @param params [Hash] request body parameters
    # @return [Object] parsed JSON response
    def patch(path, params = {})
      parse raw_patch(path, params)
    end

    ##
    # Performs a PATCH request and returns the raw response body.
    #
    # @param path [String] the URL path to request
    # @param params [Hash] request body parameters
    # @return [String] raw response body
    def raw_patch(path, params = {})
      request('PATCH', path, params)
    end

    ##
    # Performs a DELETE request and returns the parsed JSON response.
    #
    # @param path [String] the URL path to request
    # @param params [Hash] query parameters
    # @return [Object] parsed JSON response
    def delete(path, params = {})
      parse raw_delete(path, params)
    end

    ##
    # Performs a DELETE request and returns the raw response body.
    #
    # @param path [String] the URL path to request
    # @param params [Hash] query parameters
    # @return [String] raw response body
    def raw_delete(path, params = {})
      request('DELETE', path, params)
    end

    ##
    # Calculates the total URL length for a request, useful for determining
    # if a GET request should be converted to POST (when URL exceeds 2000 chars).
    #
    # @param path [String] the URL path
    # @param method [Symbol] HTTP method (default: :get)
    # @param options [Hash] request options
    # @return [Integer] the total URL length
    def url_length(path, method = :get, options = {})
      url        = build_url(path)
      request    = build_request_options_from(method.to_s.upcase, options)
      Typhoeus::Request.new(url, typhoeus_defaults.merge(options_for_typhoeus(request))).url.length
    end

    protected

    ##
    # Parses a JSON response body.
    #
    # @param body [String] the JSON response body
    # @return [Object] parsed JSON data
    def parse(body)
      MultiJson.load(body)
    end

    ##
    # Executes an HTTP request with caching and instrumentation.
    #
    # @param method [String] HTTP method (GET, POST, PUT, PATCH, DELETE)
    # @param path [String] the URL path
    # @param options [Hash] request options
    # @return [String] raw response body
    def request(method, path, options)
      url        = build_url(path)
      cache_opts = options.delete(:cache) || {}
      request    = build_request_options_from(method, options)
      descriptor = { url: url, method: method, params: request[:params] }

      instrument :request, descriptor do |descriptor|
        caching descriptor.update(cache_opts) do
          request = Typhoeus::Request.new(url, typhoeus_defaults.merge(options_for_typhoeus(request)))
          request.on_complete { |response| response_handler(response) }

          request.run.body
        end
      end
    end

    private

    ##
    # Builds a complete URL by merging the base URL with a path.
    #
    # @param path [String] the URL path
    # @return [String] the complete URL
    def build_url(path)
      base.merge(path.delete_prefix('/').squeeze('/')).to_s
    end

    ##
    # Handles HTTP responses, raising appropriate errors for non-success status codes.
    #
    # @param response [Typhoeus::Response] the HTTP response
    # @raise [Hawk::Error::Timeout] if the request timed out
    # @raise [Hawk::Error::Empty] if the response is empty
    # @raise [Hawk::Error::BadRequest] for 400 status codes
    # @raise [Hawk::Error::Forbidden] for 403 status codes
    # @raise [Hawk::Error::NotFound] for 404 status codes
    # @raise [Hawk::Error::InternalServerError] for 500 status codes
    # @raise [Hawk::Error::HTTP] for other non-success status codes
    def response_handler(response)
      return if response.success?

      req  = response.request
      url  = req.url
      meth = req.options.fetch(:method).to_s.upcase
      req_info = "#{meth} #{url}"

      if response.timed_out?
        what, secs = if response.connect_time&.zero?
                       # Connect failed
                       [:connect, req.options[:connecttimeout]]
                     else
                       [:request, req.options[:timeout]]
                     end

        raise Error::Timeout, "#{req_info}: #{what} timed out after #{secs} seconds"
      end

      case (code = response.response_code)
      when 0
        raise Error::Empty, "#{req_info}: Empty response from server (#{response.status_message})"
      when 400
        raise Error::BadRequest, "#{req_info} was a bad request"
      when 403
        raise Error::Forbidden, "#{req_info} denied access"
      when 404
        raise Error::NotFound, "#{req_info} was not found"
      when 500
        raise Error::InternalServerError, "#{req_info}: Server error (#{response.body[0..120]})"
      else
        app_error = parse_app_error_from(response.body)

        raise Error::HTTP.new(code, "#{req_info} failed with error #{code} (#{response.status_message}): #{app_error}")
      end
    end

    ##
    # Attempts to parse an application-level error message from the response body.
    #
    # @param body [String] the response body
    # @return [String, nil] the parsed error message, or nil if parsing fails
    def parse_app_error_from(body)
      if body[0] == '{' && body[-1] == '}'
        resp = begin
          MultiJson.load(body)
        rescue StandardError
          nil
        end
        if resp.respond_to?(:key?) && resp.key?('error')
          resp = resp.fetch('error')
        end
        resp
      else
        body[0..120]
      end
    end

    ##
    # Builds request options from the given HTTP method and options hash.
    #
    # @param method [String] HTTP method
    # @param options [Hash] request options
    # @return [Hash] formatted request options for Typhoeus
    def build_request_options_from(method, options)
      options = options.dup

      {}.tap do |request|
        request[:method] = method

        if options.key?(:headers)
          request[:headers] = options.delete(:headers)
        end

        if options.key?(:options)
          request.update options.delete(:options).except(:endpoint) # FIXME: SPAGHETTI
        end

        options.each do |k, v|
          if v.nil?
            options.delete(k)
          elsif v.respond_to?(:id)
            options[k] = v.id
          end
        end

        # URL-encoded only, for now.
        #
        case method
        when 'POST', 'PUT', 'PATCH'
          request[:headers] ||= {}
          request[:headers]['Content-Type'] ||= 'application/x-www-form-urlencoded'

          request[:body] = options
        when 'GET',  'DELETE'
          request[:params] = options
        else
          raise Hawk::Error, "Invalid HTTP method: #{method}"
        end
      end
    end

    ##
    # Returns frozen default options formatted for Typhoeus.
    #
    # @return [Hash] Typhoeus-compatible options
    def typhoeus_defaults
      @typhoeus_defaults ||= options_for_typhoeus(defaults).freeze
    end

    ##
    # Converts Hawk options to Typhoeus-compatible options.
    #
    # @param hawk_options [Hash] Hawk configuration options
    # @return [Hash] Typhoeus-compatible options
    def options_for_typhoeus(hawk_options)
      hawk_options.each_with_object({}) do |(opt, val), ret|
        case opt
        when :request_timeout, :timeout
          ret[:timeout] = val.to_i

        when :connect_timeout
          ret[:connecttimeout] = val.to_i

        when :username
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
      end
    end
  end
end

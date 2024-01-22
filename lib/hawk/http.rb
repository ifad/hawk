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
      timeout: 2,
      connect_timeout: 1,
      params_encoding: :rack
      # username:      nil,
      # password:      nil,
    }

    def initialize(base, options = {})
      @defaults = DEFAULTS.deep_merge(options)

      @base = URI.parse(base).tap do |url|
        unless %w[http https].include? url.scheme
          raise Error::Configuration,
                "URL '#{url}' is not valid: only http and https schemes are supported"
        end

        url.path += '/' unless %r{/$}.match?(url.path)
        url.freeze
      end
    end

    attr_reader :base, :defaults

    def inspect
      "#<#{self.class.name} to #{base}>"
    end

    def get(path, params = {})
      parse raw_get(path, params)
    end

    def raw_get(path, params = {})
      request('GET', path, params)
    end

    def post(path, params = {})
      parse raw_post(path, params)
    end

    def raw_post(path, params = {})
      request('POST', path, params)
    end

    def put(path, params = {})
      parse raw_put(path, params)
    end

    def raw_put(path, params = {})
      request('PUT', path, params)
    end

    def patch(path, params = {})
      parse raw_patch(path, params)
    end

    def raw_patch(path, params = {})
      request('PATCH', path, params)
    end

    def delete(path, params = {})
      parse raw_delete(path, params)
    end

    def raw_delete(path, params = {})
      request('DELETE', path, params)
    end

    def url_length(path, method = :get, options = {})
      url        = build_url(path)
      request    = build_request_options_from(method.to_s.upcase, options)
      Typhoeus::Request.new(url, typhoeus_defaults.merge(options_for_typhoeus(request))).url.length
    end

    protected

    def parse(body)
      MultiJson.load(body)
    end

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

    def build_url(path)
      base.merge(path.sub(%r{^/}, '')).to_s
    end

    def response_handler(response)
      return if response.success?

      req  = response.request
      url  = req.url
      meth = req.options.fetch(:method).to_s.upcase
      it   = [meth, url].join(' ')

      if response.timed_out?
        what, secs = if response.connect_time&.zero?
                       # Connect failed
                       [:connect, req.options[:connecttimeout]]
                     else
                       [:request, req.options[:timeout]]
                     end

        raise Error::Timeout, "#{it}: #{what} timed out after #{secs} seconds"
      end

      case (code = response.response_code)
      when 0
        raise Error::Empty, "#{it}: Empty response from server (#{response.status_message})"
      when 400
        raise Error::BadRequest, "#{it} was a bad request"
      when 403
        raise Error::Forbidden, "#{it} denied access"
      when 404
        raise Error::NotFound, "#{it} was not found"
      when 500
        raise Error::InternalServerError, "#{it}: Server error (#{response.body[0..120]})"
      else
        app_error = parse_app_error_from(response.body)

        raise Error::HTTP.new(code, "#{it} failed with error #{code} (#{response.status_message}): #{app_error}")
      end
    end

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

    def typhoeus_defaults
      @_typhoeus_defaults ||= options_for_typhoeus(defaults).freeze
    end

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

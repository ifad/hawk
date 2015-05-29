require 'typhoeus'

module Hawk

  ##
  # Represent an HTTP connector, to be linked to a {Model}.
  #
  class HTTP
    DEFAULTS = {
      timeout:        2,
      connecttimeout: 2
    }

    def initialize(base, options = {})
      @base    = base
      @options = DEFAULTS.merge(options)
    end

    def get(path, params = {})
      parse request(path, method: :get, params: params)
    end

    def post(path, params = {})
      parse request(path, method: :post, params: params)
    end

    protected
      def request(path, options)
        url = URI + path

        request = Typhoeus::Request.new(url, options)
        request.on_complete do |response|
          if response.success?
            #No-op
          elsif response.timed_out?
            raise Error::Timeout, "Request timed out after #{config.timeout} seconds"
          else
            case response.response_code
            when 0
              raise Error::Empty, "Empty response from server: #{response.return_message}"
            when 404
              response.options[:response_body] = response.options[:body] = ""
            when 500
              raise Error::InternalServerError, "Internal server error: #{url}"
            else
              raise Error, "HTTP Request failed: #{response.code} - #{response.return_message}"
            end
          end
        end

        request.run.response_body
      end

      def parse(body)
        MultiJson.load(body)
      end
    end

end

# frozen_string_literal: true

module Hawk
  ##
  # Base error class for all Hawk errors. Provides a hierarchy of
  # specific error types for different failure scenarios.
  #
  # @example Rescuing Hawk errors
  #   begin
  #     post = Post.find(999)
  #   rescue Hawk::Error::NotFound => e
  #     puts "Post not found: #{e.message}"
  #   rescue Hawk::Error::Timeout => e
  #     puts "Request timed out: #{e.message}"
  #   rescue Hawk::Error::HTTP => e
  #     puts "HTTP error #{e.code}: #{e.message}"
  #   end
  #
  class Error < StandardError
    ##
    # Raised when there is a configuration error, such as missing URL
    # or invalid options.
    #
    # @example
    #   raise Hawk::Error::Configuration, "URL is not set"
    class Configuration < self
    end

    ##
    # Raised when a timeout occurs while fetching from the remote HTTP server.
    # This can be either a connection timeout or a request timeout.
    #
    # @example
    #   raise Hawk::Error::Timeout, "Request timed out after 30 seconds"
    class Timeout < self
    end

    ##
    # Represents an HTTP error with a specific status code. This is the
    # base class for all HTTP-specific error types.
    #
    # @attr_reader code [Integer] the HTTP status code
    class HTTP < self
      ##
      # Initializes a new HTTP error with the given code and message.
      #
      # @param code [Integer] the HTTP status code
      # @param message [String] the error message
      def initialize(code, message)
        @code = code
        super(message)
      end

      ##
      # Returns the HTTP status code.
      #
      # @return [Integer] the HTTP status code
      attr_reader :code
    end

    ##
    # Raised when the server returns an empty response (status code 0).
    #
    # @example
    #   raise Hawk::Error::Empty, "Empty response from server"
    class Empty < HTTP
      ##
      # @param message [String] the error message
      def initialize(message)
        super(0, message)
      end
    end

    ##
    # Raised when the server returns a 500 Internal Server Error.
    #
    # @example
    #   raise Hawk::Error::InternalServerError, "Server error"
    class InternalServerError < HTTP
      ##
      # @param message [String] the error message
      def initialize(message)
        super(500, message)
      end
    end

    ##
    # Raised when the server returns a 400 Bad Request.
    #
    # @example
    #   raise Hawk::Error::BadRequest, "Invalid parameters"
    class BadRequest < HTTP
      ##
      # @param message [String] the error message
      def initialize(message)
        super(400, message)
      end
    end

    ##
    # Raised when the server returns a 404 Not Found.
    #
    # @example
    #   raise Hawk::Error::NotFound, "Resource not found"
    class NotFound < HTTP
      ##
      # @param message [String] the error message
      def initialize(message)
        super(404, message)
      end
    end

    ##
    # Raised when the server returns a 403 Forbidden.
    #
    # @example
    #   raise Hawk::Error::Forbidden, "Access denied"
    class Forbidden < HTTP
      ##
      # @param message [String] the error message
      def initialize(message)
        super(403, message)
      end
    end
  end
end

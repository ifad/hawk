# frozen_string_literal: true

module Hawk
  # Represents an error in the Hawk module.
  class Error < StandardError
    # Raised when there is a configuration error.
    class Configuration < self
    end

    # Raised when a timeout occurs while fetching from the remote HTTP server.
    class Timeout < self
    end

    # Represents an HTTP error.
    class HTTP < self
      # @param code [Integer] the HTTP status code
      # @param message [String] the error message
      def initialize(code, message)
        @code = code
        super(message)
      end

      # @return [Integer] the HTTP status code
      attr_reader :code
    end

    # Raised when the server returns an empty response.
    class Empty < HTTP
      # @param message [String] the error message
      def initialize(message)
        super(0, message)
      end
    end

    # Raised when the server returns a 500 Internal Server Error.
    class InternalServerError < HTTP
      # @param message [String] the error message
      def initialize(message)
        super(500, message)
      end
    end

    # Raised when the server returns a 400 Bad Request.
    class BadRequest < HTTP
      # @param message [String] the error message
      def initialize(message)
        super(400, message)
      end
    end

    # Raised when the server returns a 404 Not Found.
    class NotFound < HTTP
      # @param message [String] the error message
      def initialize(message)
        super(404, message)
      end
    end

    # Raised when the server returns a 403 Forbidden.
    class Forbidden < HTTP
      # @param message [String] the error message
      def initialize(message)
        super(403, message)
      end
    end
  end
end

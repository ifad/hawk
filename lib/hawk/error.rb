module Hawk
  ##
  # Represents an error.
  #
  class Error < StandardError
    # Usage error
    #
    class Configuration < self
    end

    # Timeout occurrew when fetching from the remote HTTP server.
    #
    class Timeout < self
    end

    class HTTP < self
      def initialize(code, message)
        @code = code
        super(message)
      end

      attr_reader :code
    end

    # Empty response from server.
    #
    class Empty < HTTP
      def initialize(message)
        super(0, message)
      end
    end

    # Server bailed with a 500.
    #
    class InternalServerError < HTTP
      def initialize(message)
        super(500, message)
      end
    end

    # Server bailed with a 400
    #
    class BadRequest < HTTP
      def initialize(message)
        super(400, message)
      end
    end

    # Server bailed with a 404
    #
    class NotFound < HTTP
      def initialize(message)
        super(404, message)
      end
    end

    # Server bailed with a 403
    #
    class Forbidden < HTTP
      def initialize(message)
        super(403, message)
      end
    end
  end
end

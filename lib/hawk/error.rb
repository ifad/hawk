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

    # Empty response from server.
    #
    class Empty < self
    end

    # Server bailed with a 500.
    #
    class InternalServerError < self
    end

    # Server bailed with a 404
    #
    class NotFound < self
    end
  end

end

module Hawk
  module Rake
    ##
    # Assorted utilities.
    #
    module Utils
      extend self

      ##
      # Captures the stdout emitted by the given +block+
      #
      # @return [String] the captured output
      #
      def capture_stdout
        stdout = $stdout
        string = StringIO.new
        $stdout = string

        yield

        string.tap(&:rewind).read
      ensure
        $stdout = stdout
      end

      ##
      # @return [String] the current gemfile name
      #
      def gemfile
        gemfile = ENV['BUNDLE_GEMFILE']

        File.basename(gemfile, '.*') if gemfile
      end
    end
  end
end

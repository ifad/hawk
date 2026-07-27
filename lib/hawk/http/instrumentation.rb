# frozen_string_literal: true

require 'cgi/escape'

module Hawk
  class HTTP
    ##
    # Provides request instrumentation and logging for Hawk HTTP requests.
    # Logs request details including method, URL, elapsed time, and cache status.
    #
    # @example Suppressing verbose output
    #   Hawk::HTTP::Instrumentation.suppress_verbose_output true
    #
    # @example Using with Instrumenter gem
    #   # If the Instrumenter gem is available, it will be used automatically
    #   # for more advanced instrumentation
    #
    module Instrumentation
      ##
      # Includes the appropriate instrumentation module based on available gems.
      #
      # @param base [Class] the HTTP class to instrument
      def self.included(base)
        # https://github.com/ifad/instrumenter
        if defined?(::Instrumenter)
          Instrumenter.instrument base, :hawk # FIXME: user-replaceable
        else
          base.instance_eval { include Basic }
        end
      end

      ##
      # Controls whether verbose output is suppressed.
      #
      # @param value [Boolean, nil] true to suppress, false to enable, nil to query
      # @return [Boolean] current suppression state
      def self.suppress_verbose_output(value = nil)
        if value.nil?
          @suppress_verbose_output
        else
          @suppress_verbose_output = value
        end
      end

      ##
      # Basic instrumentation that logs request details to stderr.
      #
      # @example
      #   # Output format:
      #   # >> Hawk request: GET https://api.example.com/posts (123.45ms), cache MISS
      #
      module Basic
        ##
        # Log format for request output.
        LOG_FORMAT = ">> \033[1mHawk %<type>s: %<method>s %<url>s (%<elapsed>.2fms), cache %<cached>s\033[0m\n"

        ##
        # Instruments a request by logging its details.
        #
        # @param type [Symbol] the instrumentation type (e.g., :request)
        # @param payload [Hash] request details (url, method, params)
        # @yield block to execute and measure
        # @return [Object] the block's return value
        def instrument(type, payload)
          if Hawk::HTTP::Instrumentation.suppress_verbose_output
            yield payload
          else
            start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
            ret = yield payload
            elapsed = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start) * 1000

            url = payload[:url].to_s.dup
            if payload[:params].present?
              url << '?' << payload[:params].map { |k, v| "#{k}=#{v}" }.join('&')
            end

            $stderr.printf format(
              LOG_FORMAT,
              type: type,
              method: payload[:method],
              url: CGI.unescape(url),
              elapsed: elapsed,
              cached: payload[:cached] ? 'HIT' : 'MISS'
            )

            ret
          end
        end
      end
    end
  end
end

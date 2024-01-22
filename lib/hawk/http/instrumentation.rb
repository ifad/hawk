# frozen_string_literal: true

require 'cgi'

module Hawk
  class HTTP
    module Instrumentation
      def self.included(base)
        # https://github.com/ifad/instrumenter
        if defined?(::Instrumenter)
          Instrumenter.instrument base, :hawk # FIXME: user-replaceable
        else
          base.instance_eval { include Basic }
        end
      end

      def self.suppress_verbose_output(value = nil)
        if value.nil?
          @suppress_verbose_output
        else
          @suppress_verbose_output = value
        end
      end

      module Basic
        LOG_FORMAT = ">> \033[1mHawk %<type>s: %<method>s %<url>s (%<elapsed>.2fms), cache %<cached>s\033[0m\n"

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

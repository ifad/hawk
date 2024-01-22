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
        def instrument(type, payload)
          if Hawk::HTTP::Instrumentation.suppress_verbose_output
            yield payload
          else
            start = Time.now.to_f
            ret = yield payload
            elapsed = (Time.now.to_f - start) * 1000

            url = payload[:url].to_s
            if payload[:params].present?
              url << '?' << payload[:params].inject('') { |s, (k, v)| s << [k, '=', v, '&'].join }.chomp('&')
            end

            $stderr.printf ">> \033[1mHawk #{type}: #{payload[:method]} %s (%.2fms), cache %s\033[0m\n" % [
              CGI.unescape(url),
              elapsed,
              payload[:cached] ? 'HIT' : 'MISS'
            ]

            ret
          end
        end
      end
    end
  end
end

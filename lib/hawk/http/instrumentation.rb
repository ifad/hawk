module Hawk
  class HTTP

    module Instrumentation
      def self.included(base)
        # https://github.com/ifad/instrumenter
        if defined?(::Instrumenter)
          Instrumenter.instrument base, :hawk # FIXME use-replaceable
        else
          base.instance_eval { include Basic }
        end
      end

      module Basic
        def instrument(type, payload, &block)
          start = Time.now.to_f
          ret = block.call payload
          elapsed = (Time.now.to_f - start) * 1000

          url = payload[:url].to_s
          if payload[:params] && payload[:params].size > 0
            url << '?' << payload[:params].inject('') {|s, (k,v)| s << [k, '=', v, '&'].join }.chomp('&')
          end

          $stderr.printf ">> \033[1mHawk #{type}: #{payload[:method]} #{url} (%.2fms), cache %s\033[0m\n" % [
            elapsed,
            payload[:cached] ? 'HIT' : 'MISS'
          ]

          return ret
        end
      end
    end

  end
end

# frozen_string_literal: true

module Hawk
  module Model
    module Schema
      class DSL
        def self.eval(code, &block)
          new(code).each(&block)
        end

        def initialize(code)
          @types = Hash.new { |h, k| h[k] = [] }

          instance_eval(&code)
        end

        def each(&block)
          @types.each(&block)
        end

        def method_missing(meth, *args)
          @types[meth] += args
        end
      end
    end
  end
end

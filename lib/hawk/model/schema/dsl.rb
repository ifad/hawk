# frozen_string_literal: true

module Hawk
  module Model
    module Schema
      ##
      # A DSL for defining schema types in a declarative way.
      # Used internally by the Schema module to parse schema definitions.
      #
      # @example Using the DSL
      #   DSL.eval do
      #     integer :id
      #     string :title, :body
      #     datetime :created_at
      #     boolean :published
      #   end
      #
      class DSL
        ##
        # Evaluates a DSL block and yields the resulting type-attributes pairs.
        #
        # @param code [Proc] the DSL block
        # @yield [type, attributes] each type and its attributes
        def self.eval(code, &block)
          new(code).each(&block)
        end

        ##
        # Initializes the DSL with the given code block.
        #
        # @param code [Proc] the DSL block to evaluate
        def initialize(code)
          @types = Hash.new { |h, k| h[k] = [] }

          instance_eval(&code)
        end

        ##
        # Iterates over each type-attributes pair.
        #
        # @yield [type, attributes] each type and its attributes
        def each(&block)
          @types.each(&block)
        end

        ##
        # Handles unknown methods by treating them as type definitions.
        #
        # @param meth [Symbol] the type name (e.g., :integer, :string)
        # @param args [Array] the attribute names
        def method_missing(meth, *args)
          @types[meth] += args
        end
      end
    end
  end
end

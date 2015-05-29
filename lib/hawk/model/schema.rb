module Hawk
  module Model

    module Schema
      def self.included(base)
        base.extend ClassMethods
      end

      def initialize(attributes = {})
        cast!(attributes)
        # super not required, this is the last in the chain.
      end

      def attributes
        schema.each_key.inject({}) do |ret, key|
          ret.update(key => read_attribute(key))
        end
      end

      def read_attribute(name)
        instance_variable_get(['@', name].join)
      end

      def write_attribute(name, value)
        instance_variable_set(['@', name].join, value)
      end
      private :write_attribute # For now

      def inspect
        attributes = schema.inject('') {|s, (k,v)|
          s << " #{k}=#{read_attribute(k).inspect}"
        }
        "#<#{self.class.name}#{attributes}>"
      end

      private
        def cast!(attributes)
          schema(attributes).each do |key, caster|
            next unless value = attributes.fetch(key, nil)
            value = caster.call(value) if caster
            write_attribute key, value
          end
        end

        def schema(attributes = nil)
          if attributes && self.class.schema.nil?
            self.class.define_schema_from(attributes)
          end
          self.class.schema
        end

      module ClassMethods
        def inherited(subclass)
          super
          if self.schema
            subclass.instance_variable_set :@_schema, self.schema
          end
        end

        def schema
          @_schema
        end

        def define_schema_from(attributes)
          @_schema = {}

          attributes.each_key do |key|
            _, @_schema[key] = CASTERS.find {|re,| key =~ re }

            attr_reader key
          end
        end
      end

      CASTERS = {
        /_(?:at|from|until|on)$/ =>
          -> (value) { Time.parse(value) }                ,

        /_date$/ =>
          -> (value) { Date.parse(value) }                ,

        /_num$/ =>
          -> (value) { BigDecimal.new(value) }            ,

        /^is_/ =>
          -> (value) { value.in? ['1', 'true', 1, true] } ,
      }
    end

  end
end

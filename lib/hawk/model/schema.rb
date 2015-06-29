module Hawk
  module Model

    module Schema
      def self.included(base)
        base.extend ClassMethods
      end

      def initialize(attributes = {}, params = {})
        cast!(attributes)
        # super not required, this is the last in the chain.
      end

      def attributes
        schema.each_key.inject({}) do |ret, key|
          ret.update(key => read_attribute(key))
        end
      end
      alias to_h attributes

      def as_json(*ignored) # FIXME
        to_h
      end

      def read_attribute(name)
        instance_variable_get(['@', name].join)
      end

      def write_attribute(name, value)
        instance_variable_set(['@', name].join, value)
      end
      private :write_attribute # For now

      private
        def cast!(attributes)
          schema(attributes).each do |key, caster|
            next unless value = attributes.fetch(key, nil)
            value = caster.call(value) if caster
            write_attribute key, value
          end
        end

        def schema(attributes = nil)
          defined_attributes = self.class.schema || {}

          if attributes && attributes.size > defined_attributes.size
            self.class.define_schema_from(attributes)
          end
          self.class.schema || {}
        end

      module ClassMethods
        def inherited(subclass)
          super
          subclass.instance_variable_set :@_schema,       self.schema       if self.schema
          subclass.instance_variable_set :@_after_schema, self.after_schema if self.after_schema
        end

        def schema
          @_schema
        end

        def define_schema_from(attributes)
          @_schema = {}

          attributes.each_key do |key|
            if (caster = find_schema_caster_for(key))
              @_schema[key] = caster.code
              # Else it is read as-is
            end

            attr_reader key
          end

          if after_schema
            class_eval(&after_schema)
          end
        end

        def schema_type_of(attribute_name)
          if (caster = find_schema_caster_for(attribute_name))
            caster.type
          else
            :string
          end
        end

        def find_schema_caster_for(attribute)
          _, caster = CASTERS.find {|re,| attribute =~ re }
          return caster
        end

        def after_schema(&block)
          @_after_schema = block if block
          @_after_schema
        end
      end

      class Caster < Struct.new(:type, :code)
      end

      CASTERS = {
        /_(?:at|from|until|on)$/ =>
          Caster.new(:datetime, -> (value) { Time.parse(value) })                ,

        /_date$/ =>
          Caster.new(:date,     -> (value) { Date.parse(value) })                ,

        /_num$/ =>
          Caster.new(:integer,  -> (value) { BigDecimal.new(value) })            ,

        /^is_/ =>
          Caster.new(:boolean,  -> (value) { value.in? ['1', 'true', 1, true] }) ,
      }
    end

  end
end

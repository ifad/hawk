module Hawk
  module Model
    module Schema
      def self.included(base)
        base.extend ClassMethods
      end

      def initialize(attributes = {}, _params = {})
        cast!(attributes)
        # super not required, this is the last in the chain.
      end

      def attributes
        schema.each_key.inject({}) do |ret, key|
          ret.update(key => read_attribute(key))
        end
      end
      alias to_h attributes

      def as_json(*_ignored) # FIXME
        to_h
      end

      def read_attribute(name)
        get_attribute(name)
      end

      def write_attribute(name, value)
        set_attribute(name, value)
      end

      private

      def get_attribute(name)
        instance_variable_get(['@', name].join)
      end

      def set_attribute(name, value)
        instance_variable_set(['@', name].join, value)
      end

      def cast!(attributes)
        schema(attributes).each do |key, caster|
          next unless attributes.key?(key)

          value = attributes.fetch(key, nil)
          value = caster.call(value) if caster

          set_attribute key, value
        end
      end

      def schema(attributes = nil)
        if attributes.present? && self.class.schema.nil?
          self.class.define_schema_from(attributes)
        end
        self.class.schema || {}
      end

      autoload :DSL, 'hawk/model/schema/dsl'

      module ClassMethods
        def inherited(subclass)
          super
          subclass.instance_variable_set :@_schema,       schema       if schema
          subclass.instance_variable_set :@_after_schema, after_schema if after_schema
        end

        def schema(&block)
          define_schema_via_dsl(&block) if block

          @_schema
        end

        def define_schema_via_dsl(&code)
          @_schema = {}

          DSL.eval(code) do |type, attributes|
            attributes.each do |attribute|
              define_schema_key(attribute.to_s, find_schema_caster_typed(type))
            end
          end
        end

        def define_schema_from(attributes)
          @_schema = {}

          attributes.each_key do |attribute|
            define_schema_key(attribute.to_s, find_schema_caster_for(attribute))
          end

          if after_schema
            class_eval(&after_schema)
          end
        end

        def define_schema_key(key, caster)
          return if association?(key)

          @_schema[key] = caster

          define_method(key) do
            read_attribute(key)
          end

          define_method(:"#{key}=") do |value|
            write_attribute(key, value)
          end

          if caster && caster.type == :boolean
            define_method(:"#{key}?") { !!send(key) }
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
          ATTRIBUTE_CASTS.each do |re, type|
            if attribute&.match?(re)
              return find_schema_caster_typed(type)
            end
          end

          nil
        end

        def find_schema_caster_typed(type)
          CASTERS.fetch(type, nil)
        end

        def after_schema(&block)
          @_after_schema = block if block
          @_after_schema
        end
      end

      class Caster
        def initialize(type, code)
          @type = type
          @code = code
        end
        attr_reader :type

        def call(value)
          @code.call(value) unless value.nil?
        rescue StandardError => e
          "## Error while casting #{value} to #{type}: #{e.message} ##"
        end

        def to_s
          src, line = @code.source_location
          "#<Cast to #{type} using #{File.basename(src)}:#{line})>"
        end
        alias inspect to_s
        alias pretty_inspect to_s
      end

      bools = Set.new(['1', 'true', 1, true])
      CASTERS = [
        Caster.new(:integer,  ->(value) { Integer(value) }),
        Caster.new(:float,    ->(value) { Float(value) }),
        Caster.new(:datetime, ->(value) { Time.parse(value) }),
        Caster.new(:date,     ->(value) { Date.parse(value) }),
        Caster.new(:bignum,   ->(value) { BigDecimal(value) }),
        Caster.new(:boolean,  ->(value) { bools.include?(value) })
      ].inject({}) { |h, c| h.update(c.type => c) }

      ATTRIBUTE_CASTS = {
        /_(?:at|from|until|on)$/ => :datetime,
        /_date$/ => :date,
        /_num$/ => :bignum,
        /^is_/ => :boolean
      }
    end
  end
end

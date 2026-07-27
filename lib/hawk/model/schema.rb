# frozen_string_literal: true

module Hawk
  module Model
    ##
    # Provides schema definition and attribute casting for Hawk models.
    # Automatically infers data types from attribute names and provides
    # type casting for common patterns like dates, booleans, and numbers.
    #
    # @example Defining a schema
    #   class Post < Hawk::Model::Base
    #     schema do
    #       integer :id
    #       string :title, :body
    #       datetime :created_at
    #       boolean :published
    #     end
    #   end
    #
    # @example Automatic type casting
    #   # Attributes ending in _at, _from, _until, _on are cast to DateTime
    #   # Attributes ending in _date are cast to Date
    #   # Attributes ending in _num are cast to BigDecimal
    #   # Attributes starting with is_ are cast to Boolean
    #   class Event < Hawk::Model::Base
    #     schema do
    #       string :name
    #     end
    #   end
    #
    #   # created_at will be automatically cast to DateTime
    #   event = Event.new(created_at: "2024-01-15T10:30:00Z")
    #   event.created_at.class # => Time
    #
    module Schema
      ##
      # Extends the including model with class-level schema definition helpers.
      #
      # @param base [Class] the model class including the schema helpers
      def self.included(base)
        base.extend ClassMethods
      end

      ##
      # Initializes the model with the given attributes, casting values
      # according to the schema definition.
      #
      # @param attributes [Hash] attribute key-value pairs
      def initialize(attributes = {}, _params = {})
        cast!(attributes)
        # super not required, this is the last in the chain.
      end

      ##
      # Returns a hash of all attributes and their current values.
      #
      # @return [Hash] attribute key-value pairs
      def attributes
        schema.each_key.inject({}) do |ret, key|
          ret.update(key => read_attribute(key))
        end
      end
      alias to_h attributes

      ##
      # Returns the attributes hash for JSON serialization.
      #
      # @return [Hash] attribute key-value pairs
      def as_json(*_ignored) # FIXME
        to_h
      end

      ##
      # Reads the value of an attribute by name.
      #
      # @param name [String, Symbol] the attribute name
      # @return [Object] the attribute value
      def read_attribute(name)
        get_attribute(name)
      end

      ##
      # Writes a value to an attribute by name.
      #
      # @param name [String, Symbol] the attribute name
      # @param value [Object] the value to set
      def write_attribute(name, value)
        set_attribute(name, value)
      end

      private

      ##
      # Gets an attribute value from the instance variable.
      #
      # @param name [String] the attribute name
      # @return [Object] the attribute value
      def get_attribute(name)
        instance_variable_get(['@', name].join)
      end

      ##
      # Sets an attribute value in the instance variable.
      #
      # @param name [String] the attribute name
      # @param value [Object] the value to set
      def set_attribute(name, value)
        instance_variable_set(['@', name].join, value)
      end

      ##
      # Casts all attributes according to the schema definition.
      #
      # @param attributes [Hash] attribute key-value pairs
      def cast!(attributes)
        schema(attributes).each do |key, caster|
          next unless attributes.key?(key)

          value = attributes.fetch(key, nil)
          value = caster.call(value) if caster

          set_attribute key, value
        end
      end

      ##
      # Returns the schema definition for this model.
      #
      # @param attributes [Hash, nil] optional attributes to define schema from
      # @return [Hash] schema definition mapping attribute names to casters
      def schema(attributes = nil)
        if attributes.present? && self.class.schema.nil?
          self.class.define_schema_from(attributes)
        end
        self.class.schema || {}
      end

      autoload :DSL, 'hawk/model/schema/dsl'

      ##
      # Class-level schema definition and inference helpers.
      module ClassMethods
        ##
        # Inherits schema definition from parent class.
        def inherited(subclass)
          super
          subclass.instance_variable_set :@_schema,       schema       if schema
          subclass.instance_variable_set :@_after_schema, after_schema if after_schema
        end

        ##
        # Defines or returns the schema for this model.
        #
        # @yield [dsl] block to define schema using DSL methods
        # @return [Hash, nil] the schema definition
        #
        # @example Defining a schema
        #   class Post < Hawk::Model::Base
        #     schema do
        #       integer :id
        #       string :title
        #     end
        #   end
        def schema(&block)
          define_schema_via_dsl(&block) if block

          @_schema
        end

        ##
        # Defines the schema using the DSL.
        #
        # @param code [Proc] block containing schema definition
        def define_schema_via_dsl(&code)
          @_schema = {}

          DSL.eval(code) do |type, attributes|
            attributes.each do |attribute|
              define_schema_key(attribute.to_s, find_schema_caster_typed(type))
            end
          end
        end

        ##
        # Defines schema from a hash of attributes (used for automatic schema inference).
        #
        # @param attributes [Hash] attribute names to infer schema from
        def define_schema_from(attributes)
          @_schema = {}

          attributes.each_key do |attribute|
            define_schema_key(attribute.to_s, find_schema_caster_for(attribute))
          end

          if after_schema
            class_eval(&after_schema)
          end
        end

        ##
        # Defines a single schema key with its caster, generating getter, setter,
        # and optionally a predicate method for booleans.
        #
        # @param key [String] the attribute name
        # @param caster [Caster, nil] the type caster
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

        ##
        # Returns the schema type for a given attribute.
        #
        # @param attribute_name [String, Symbol] the attribute name
        # @return [Symbol] the attribute type
        def schema_type_of(attribute_name)
          if (caster = find_schema_caster_for(attribute_name))
            caster.type
          else
            :string
          end
        end

        ##
        # Finds the appropriate caster for an attribute based on its name.
        #
        # @param attribute [String] the attribute name
        # @return [Caster, nil] the caster for this attribute
        def find_schema_caster_for(attribute)
          ATTRIBUTE_CASTS.each do |re, type|
            if attribute&.match?(re)
              return find_schema_caster_typed(type)
            end
          end

          nil
        end

        ##
        # Returns the caster for a given type.
        #
        # @param type [Symbol] the type name
        # @return [Caster, nil] the caster for this type
        def find_schema_caster_typed(type)
          CASTERS.fetch(type, nil)
        end

        ##
        # Defines a callback to be executed after schema is defined.
        #
        # @yield block to execute after schema definition
        def after_schema(&block)
          @_after_schema = block if block
          @_after_schema
        end
      end

      ##
      # Represents a type caster that converts values to a specific type.
      #
      # @attr_reader type [Symbol] the type this caster converts to
      class Caster
        ##
        # Initializes a new caster with the given type and conversion code.
        #
        # @param type [Symbol] the type name
        # @param code [Proc] the conversion lambda
        def initialize(type, code)
          @type = type
          @code = code
        end
        attr_reader :type

        ##
        # Casts a value to this caster's type.
        #
        # @param value [Object] the value to cast
        # @return [Object, String, nil] the cast value; nil if input is nil; an error message String if casting raises
        def call(value)
          @code.call(value) unless value.nil?
        rescue StandardError => e
          "## Error while casting #{value} to #{type}: #{e.message} ##"
        end

        ##
        # Returns a string representation of the caster.
        #
        # @return [String] human-readable representation
        def to_s
          src, line = @code.source_location
          "#<Cast to #{type} using #{File.basename(src)}:#{line})>"
        end
        alias inspect to_s
        alias pretty_inspect to_s
      end

      ##
      # Boolean values that are considered truthy.
      BOOLS = Set.new(['1', 'true', 1, true]).freeze
      private_constant :BOOLS

      ##
      # Built-in type casters.
      CASTERS = [
        Caster.new(:integer,  ->(value) { Integer(value) }),
        Caster.new(:float,    ->(value) { Float(value) }),
        Caster.new(:datetime, ->(value) { Time.parse(value) }),
        Caster.new(:date,     ->(value) { Date.parse(value) }),
        Caster.new(:bignum,   ->(value) { BigDecimal(value) }),
        Caster.new(:boolean,  ->(value) { BOOLS.include?(value) })
      ].inject({}) { |h, c| h.update(c.type => c) }
      private_constant :CASTERS

      ##
      # Patterns for automatic type inference from attribute names.
      ATTRIBUTE_CASTS = {
        /_(?:at|from|until|on)$/ => :datetime,
        /_date$/ => :date,
        /_num$/ => :bignum,
        /^is_/ => :boolean
      }.freeze
      private_constant :ATTRIBUTE_CASTS
    end
  end
end

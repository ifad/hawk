# frozen_string_literal: true

module Hawk
  ##
  # Allows adding to any Ruby object an accessor referencing an {Hawk::Model}.
  #
  # This module provides a convenient way to define resource accessors that
  # lazily load and memoize associated Hawk models based on ID attributes.
  #
  # @example Defining a monomorphic resource accessor
  #   class Foo
  #     include Hawk::Linker
  #
  #     resource_accessor :bar
  #   end
  #
  #   # Now, Foo#bar will call Bar.find(bar_id) and memoize it
  #
  # @example Defining a polymorphic resource accessor
  #   class Image
  #     include Hawk::Linker
  #
  #     resource_accessor :imageable, polymorphic: true
  #   end
  #
  module Linker
    ##
    # Extends the including class with class-level resource accessor macros.
    #
    # @param base [Class] the class including the linker helpers
    def self.included(base)
      base.extend(ClassMethods)
    end

    ##
    # Class-level macros for defining resource accessors.
    module ClassMethods
      ##
      # Defines a method to access a resource for a given entity, with support
      # for both polymorphic and monomorphic resource accessors.
      #
      # @param entity [Symbol] the entity name for which the accessor is defined
      # @param options [Hash] options to customize the accessor behavior
      # @option options [Boolean] :polymorphic (false) if true, uses polymorphic accessor
      # @option options [String] :class_name the class name to use (defaults to entity name camelize)
      # @option options [String] :primary_key the primary key (defaults to <tt>"#{entity}_id"</tt>)
      # @option options [String] :as the base name for polymorphic type/id columns
      #
      # @return [void]
      def resource_accessor(entity, options = {}) # Let's start simple.
        if options[:polymorphic]
          _polymorphic_resource_accessor(entity, options)
        else
          _monomorphic_resource_accessor(entity, options)
        end
      end

      private

      ##
      # Defines a monomorphic resource accessor with getter, setter, and reloader methods.
      #
      # @param entity [Symbol] the entity name
      # @param options [Hash] accessor options
      # @return [void]
      def _monomorphic_resource_accessor(entity, options)
        klass = options[:class_name] || entity.to_s.camelize
        key   = options[:primary_key] || [entity, :id].join('_')

        class_eval <<~RUBY, __FILE__, __LINE__ + 1 # Getter
          def #{entity}
            return nil unless self.#{key}.present?

            @_#{entity} ||= #{module_parent}::#{klass}.find(self.#{key})
          end
        RUBY

        class_eval <<~RUBY, __FILE__, __LINE__ + 1 # Setter
          def #{entity}=(object)
            return if object.blank?

            unless object.respond_to?(:id) && object.class.respond_to?(:find)
              raise ArgumentError, "Invalid object: \#{object.inspect}"
            end

            self.#{key} = object.id

            @_#{entity} = object
          end
        RUBY

        class_eval <<~RUBY, __FILE__, __LINE__ + 1 # Reloader
          def reload(*)
            super.tap { @_#{entity} = nil }
          end
        RUBY
      end

      ##
      # Defines a polymorphic resource accessor with getter, setter, and reloader methods.
      #
      # @param entity [Symbol] the entity name
      # @param options [Hash] accessor options
      # @return [void]
      def _polymorphic_resource_accessor(entity, options)
        key = options[:as] || entity

        class_eval <<~RUBY, __FILE__, __LINE__ + 1 # Getter
          def #{entity}
            return nil unless self.#{key}_id.present? && self.#{key}_type.present?

            @_#{entity} ||= self.#{key}_type.constantize.find(self.#{key}_id)
          end
        RUBY

        class_eval <<~RUBY, __FILE__, __LINE__ + 1 # Setter
          def #{entity}=(object)
            return if object.blank?

            unless object.respond_to?(:id) && object.class.respond_to?(:find)
              raise ArgumentError, "Invalid object: \#{object.inspect}"
            end

            self.#{key}_type = object.class.name
            self.#{key}_id   = object.id

            @_#{entity} = object
          end
        RUBY

        class_eval <<~RUBY, __FILE__, __LINE__ + 1 # Reloader
          def reload(*)
            super.tap { @_#{entity} = nil }
          end
        RUBY
      end
    end
  end
end

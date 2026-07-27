# frozen_string_literal: true

require 'active_model'

module Hawk
  module Model
    ##
    # Integrates Hawk models with ActiveModel, providing persistence,
    # dirty tracking, and equality comparison based on IDs.
    #
    # @example Using ActiveModel features
    #   post = Post.new(title: "Hello")
    #   post.persisted? # => true (always, for now)
    #   post.save! # => PUT request to API
    #
    #   # Dirty tracking
    #   post.title = "Updated"
    #   post.changed? # => true
    #   post.changes # => { "title" => ["Hello", "Updated"] }
    #
    module Active
      ##
      # Extends the including model with ActiveModel naming, conversion,
      # translation, and dirty tracking behaviour.
      #
      # @param base [Class] the model class including the Active integration
      def self.included(base)
        base.instance_eval do
          extend ActiveModel::Naming
          extend ActiveModel::Translation

          include ActiveModel::Conversion
          include ActiveModel::Dirty

          def define_schema_key(key, *)
            super
            define_attribute_method key
          end
        end
      end

      ##
      # Compares two model instances by class and ID.
      #
      # @param other [Object] the object to compare with
      # @return [Boolean] true if both instances have the same class and ID
      # @raise [Hawk::Error] if the model doesn't have an id attribute
      def ==(other)
        unless respond_to?(:id)
          raise Error, "Can't compare #{self} as it doesn't have an .id attribute"
        end

        other.instance_of?(self.class) && id == other.id
      end
      alias eql? ==

      ##
      # Returns a hash value based on the ID for use in hashes and sets.
      #
      # @return [Integer] the hash value
      def hash
        if respond_to?(:id) && !id.nil?
          id.hash
        else
          super
        end
      end

      ##
      # Returns whether the model is persisted.
      #
      # @return [Boolean] always true (naive implementation for now)
      def persisted?
        true # Naive, for now.
      end

      ##
      # Writes an attribute value and marks it as changed.
      #
      # @param name [String, Symbol] the attribute name
      # @param value [Object] the value to set
      def write_attribute(name, value)
        attribute_will_change!(name)
        super
      end

      ##
      # Saves the model to the API using a PUT request.
      #
      # @return [Boolean] true on success
      # @raise [Hawk::Error] on failure
      def save!
        persist!
        changes_applied
        true
      end

      ##
      # Saves the model, returning false on failure instead of raising.
      #
      # @return [Boolean] true on success, false on failure
      def save
        save!
      rescue Hawk::Error
        false
      end

      ##
      # Persists the model by sending a PUT request to the API.
      #
      # @return [Object] the API response
      # @raise [Hawk::Error] on failure
      def persist!
        connection.put(path_for(nil), attributes.merge(cache: { invalidate: path_for(nil) }))
      end
    end
  end
end

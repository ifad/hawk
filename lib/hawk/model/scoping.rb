# frozen_string_literal: true

module Hawk
  module Model
    ##
    # Provides ActiveRecord-like scope methods for Hawk models.
    # Scopes are class-level methods that return a Proxy with predefined
    # query parameters.
    #
    # @example Defining scopes
    #   class Post < Hawk::Model::Base
    #     scope :published, -> { where(published: true) }
    #     scope :recent, -> { order(:created_at).limit(10) }
    #     scope :by_author, ->(name) { where(author: name) }
    #   end
    #
    # @example Using scopes
    #   Post.published # => Proxy with published: true
    #   Post.recent.order(:title) # => Chain scopes
    #   Post.by_author('John').limit(5) # => Parameters work too
    #
    module Scoping
      ##
      # Extends the including model with named scope definitions.
      #
      # @param base [Class] the model class including the scoping helpers
      def self.included(base)
        base.extend ClassMethods
      end

      ##
      # Class-level scope declaration helpers.
      module ClassMethods
        ##
        # Defines a named scope on the model class.
        #
        # @param name [Symbol] the scope name
        # @param impl [Proc] the scope implementation (should return a Proxy)
        # @raise [Hawk::Error::Configuration] if a method with this name already exists
        #
        # @example
        #   class Post < Hawk::Model::Base
        #     scope :published, -> { where(published: true) }
        #   end
        #
        #   Post.published.all # => [...]
        def scope(name, impl)
          if respond_to?(name)
            raise Error::Configuration, "#{self.name} already has a #{name} singleton method defined"
          end

          define_singleton_method(name, &impl)
        end
      end
    end
  end
end

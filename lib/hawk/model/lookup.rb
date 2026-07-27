# frozen_string_literal: true

module Hawk
  module Model
    ##
    # Provides model class lookup functionality for resolving association
    # targets. Searches within the model namespace, parent namespace, and
    # inheritance chain to find the appropriate model class.
    #
    # @example Model class resolution
    #   module Client
    #     class Base < Hawk::Model::Base
    #     end
    #
    #     class Post < Base
    #       has_many :comments
    #     end
    #
    #     class Comment < Base
    #       belongs_to :post
    #     end
    #   end
    #
    #   module App
    #     class Post < Client::Post
    #     end
    #
    #     class Comment < Client::Comment
    #     end
    #   end
    #
    #   # Returns App::Comment when called from App::Post
    #   App::Post.model_class_for('Comment')
    #
    #   # Returns Client::Comment when called from Client::Post
    #   Client::Post.model_class_for('Comment')
    #
    module Lookup
      ##
      # Extends the including model with class lookup helpers.
      #
      # @param base [Class] the model class including the lookup helpers
      def self.included(base)
        base.extend ClassMethods
      end

      ##
      # Class-level model resolution helpers.
      module ClassMethods
        ##
        # Inherits the class cache from the parent class.
        def inherited(subclass)
          super
          subclass.instance_eval { @_class_cache = {} }
        end

        ##
        # Resolves a model class by name, searching within the current
        # namespace, parent namespace, and inheritance chain.
        #
        # @param name [String] the class name to resolve
        # @param scope [Class] the scope to search from (default: self)
        # @return [Class] the resolved model class
        # @raise [Hawk::Error] if no suitable model is found
        #
        # @example
        #   Post.model_class_for('Comment') # => Comment
        def model_class_for(name, scope: self)
          cached_model_class_for(name, scope) do
            look_up_model_class(name, scope)
          end
        end

        private

        ##
        # Looks up a model class by name.
        #
        # @param name [String] the class name to resolve
        # @param scope [Class] the scope to search from
        # @return [Class] the resolved model class
        # @raise [Hawk::Error] if no suitable model is found
        def look_up_model_class(name, scope)
          if self_constant = look_up_constant_in(name, scope)
            return self_constant
          end

          scope_parent = scope.module_parent

          if (parent_constant = look_up_constant_in(name, scope_parent))
            return parent_constant
          end

          # Look up one level
          #
          if scope.superclass < Hawk::Model::Base
            model_class_for(name, scope: scope.superclass)
          else
            raise Hawk::Error, "Can't find a suitable model for #{name}"
          end
        end

        ##
        # Attempts to find a constant within a given scope.
        #
        # @param name [String] the constant name
        # @param scope [Class, Module] the scope to search in
        # @return [Class, nil] the constant, or nil if not found
        def look_up_constant_in(name, scope)
          scope.module_parent.const_get(name)
        rescue NameError
          nil
        end

        ##
        # Caches the result of model class resolution.
        #
        # @param name [String] the class name
        # @param scope [Class] the scope
        # @yield block that returns the resolved class
        # @return [Class] the cached model class
        def cached_model_class_for(name, scope)
          @_class_cache[[name, scope.name]] ||= yield
        end
      end
    end
  end
end

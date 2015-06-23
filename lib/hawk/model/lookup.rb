module Hawk
  module Model

    module Lookup
      using Hawk::Polyfills # Module#parent

      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        # Given
        #
        #   module Client
        #     module Base < Hawk::Model::Base
        #     end
        #
        #     module Post < Base
        #       has_many :comments
        #     end
        #
        #     module Comment < Base
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
        # Then
        #
        #   App::Post.model_class_for('Comment')
        #
        # will return `App::Comment`
        #
        # while
        #
        #   Client::Post.model_class_for('Comment')
        #
        # will return `Client::Comment`
        #
        # In a nutshell, first the model namespace is checked,
        # then the containing namespace, and then the inheritance
        # chain is walked up to the first class inheriting from
        # Hawk::Model::Base.
        #
        def model_class_for(name, scope: self)
          if scope.const_defined?(name, inherit=false)
            return scope.const_get(name)

          elsif scope.parent.const_defined?(name, inherit=false)
            return scope.parent.const_get(name)

          end

          # Look up one level
          #
          if scope.superclass < Hawk::Model::Base
            model_class_for(name, scope: scope.superclass)
          else
            raise Hawk::Error, "Can't find a suitable model for #{name}"
          end

        end
      end
    end

  end
end

module Hawk
  module Model

    module Lookup

      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def inherited(subclass)
          super
          subclass.instance_eval { @_class_cache = {} }
        end

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
          cached_model_class_for(name, scope) do
            look_up_model_class(name, scope)
          end
        end

        private
        def look_up_model_class(name, scope)
          if self_constant = look_up_constant_in(name, scope)
            return self_constant
          end

          if (parent_constant = look_up_constant_in(name, scope.parent))
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

        def look_up_constant_in(name, scope)
          scope.parent.const_get(name)
        rescue NameError
          nil
        end

        def cached_model_class_for(name, scope, &block)
          @_class_cache[[name, scope.name]] ||= block.call
        end

      end
    end

  end
end

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
        #   module Foo
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
        # Then
        #
        #   Post.model_class_for('Comment')
        #
        # will look up a `Comment` class in `Post` first and then in `Foo`.
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

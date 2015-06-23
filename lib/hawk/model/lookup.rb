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
        # It's a bit naive. But it's convention over configuration.
        # And makes you architect stuff The Right Way, not throwing
        # randomly stuff around hoping it'll magically work. :-).
        #
        def model_class_for(name)
          self.const_defined?(name, inherit=false) ?
            self.const_get(name) :
            self.parent.const_get(name)
        end
      end
    end

  end
end

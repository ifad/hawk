module Hawk
  module Model

    module Scoping
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def scope(name, impl)
          if self.respond_to?(name)
            raise Error::Configuration, "#{self.name} already has a #{name} singleton method defined"
          end

          define_singleton_method(name, &impl)
        end
      end
    end

  end
end

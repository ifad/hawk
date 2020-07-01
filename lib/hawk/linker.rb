module Hawk

  # Allows adding to any Ruby object an accessor referencing an {Hawk::Model}.
  #
  # Example, assuming Bar is defined and Foo responds_to `bar_id`:
  #
  #     class Foo
  #       include Hawk::Linker
  #
  #       resource_accessor :bar
  #     end
  #
  # Now, Foo#bar will call Bar.find(bar_id) and memoize it
  #
  module Linker
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def resource_accessor(entity, options = {}) # Let's start simple.
        if options[:polymorphic]
          _polymorphic_resource_accessor(entity, options)
        else
          _monomorphic_resource_accessor(entity, options)
        end
      end

      private
        def _monomorphic_resource_accessor(entity, options)
          klass = options[:class_name] || entity.to_s.camelize
          key   = options[:primary_key] || [entity, :id].join('_')

          class_eval <<-RUBY, __FILE__, __LINE__ -1 # Getter
            def #{entity}
              return nil unless self.#{key}.present?

              @_#{entity} ||= #{respond_to?(:module_parent) ? module_parent : parent}::#{klass}.find(self.#{key})
            end
          RUBY

          class_eval <<-RUBY, __FILE__, __LINE__ -1 # Setter
            def #{entity}=(object)
              return if object.blank?

              unless object.respond_to?(:id) && object.class.respond_to?(:find)
                raise ArgumentError, "Invalid object: \#{object.inspect}"
              end

              self.#{key} = object.id

              @_#{entity} = object
            end
          RUBY

          class_eval <<-RUBY, __FILE__, __LINE__ -1 # Reloader
            def reload(*)
              super.tap { @_#{entity} = nil }
            end
          RUBY
        end

        def _polymorphic_resource_accessor(entity, options)
          key = options[:as] || entity

          class_eval <<-RUBY, __FILE__, __LINE__ -1 # Getter
            def #{entity}
              return nil unless self.#{key}_id.present? && self.#{key}_type.present?

              @_#{entity} ||= self.#{key}_type.constantize.find(self.#{key}_id)
            end
          RUBY

          class_eval <<-RUBY, __FILE__, __LINE__ -1 # Setter
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

          class_eval <<-RUBY, __FILE__, __LINE__ -1 # Reloader
            def reload(*)
              super.tap { @_#{entity} = nil }
            end
          RUBY
        end
    end
  end

end

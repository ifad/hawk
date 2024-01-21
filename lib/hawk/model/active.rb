require 'active_model'

module Hawk
  module Model
    module Active
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

      def ==(other)
        unless self.respond_to?(:id)
          raise Error, "Can't compare #{self} as it doesn't have an .id attribute"
        end

        other.instance_of?(self.class) && self.id == other.id
      end
      alias eql? ==

      def hash
        if respond_to?(:id) && !self.id.nil?
          self.id.hash
        else
          super
        end
      end

      def persisted?
        true # Naive, for now.
      end

      def write_attribute(name, value)
        attribute_will_change!(name)
        super
      end

      if ActiveModel::Dirty.instance_methods.include?(:changes_applied)
        def save!
          persist!
          changes_applied
          true
        end
      else
        def save!
          persist!
          @changed_attributes && @changed_attributes.clear
          true
        end
      end

      def save
        save!
      rescue Hawk::Error
        false
      end

      def persist!
        connection.put(path_for(nil), self.attributes.merge(cache: {invalidate: path_for(nil)}))
      end
    end
  end
end

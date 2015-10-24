require 'active_model/conversion'
require 'active_model/dirty'
require 'active_model/naming'
require 'active_model/translation'

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
          @changed_attributes.try(:clear)
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

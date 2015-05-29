module Hawk
  module Model

    module Finder
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def find(id)
          repr = connection.get([model_path, id].join('/'))
          repr = repr.fetch(instance_key) if repr.key?(instance_key)

          new repr
        end

        def all
          repr = connection.get(model_path)
          repr = repr.fetch(collection_key) if repr.key?(collection_key)

          repr.map! {|instance| new instance}
        end

        def instance_key
          @_instance_key ||= self.name.underscore
        end

        def collection_key
          @_collection_key = instance_key.pluralize
        end

        def model_path(path = nil)
          if self == Hawk::Model::Base
            raise Error::Configuration, "Hawk's Base class doesn't have any path"
          end

          @_model_path = path if path
          @_model_path ||= default_model_path
        end

        def default_model_path
          self.name.demodulize.underscore.pluralize.freeze
        end
      end
    end

  end
end

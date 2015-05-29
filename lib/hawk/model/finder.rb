module Hawk
  module Model

    module Finder
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def find(id)
          repr = connection.get([model_path, id].join('/'))
          repr = repr.fetch(model_key) if repr.key?(model_key)

          new repr
        end

        def model_key
          @_model_key ||= self.name.underscore
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

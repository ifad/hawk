module Hawk
  module Model

    module Finder
      def self.included(base)
        base.extend ClassMethods
      end

      def find(id)

      end

      module ClassMethods
        def model_url
          @_model_url ||= self.connection.base + model_path
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

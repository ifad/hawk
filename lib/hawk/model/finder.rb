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

        if [:demodulize, :camelize, :pluralize].all? {|m| ''.respond_to?(m)}
          def default_model_path
            self.name.demodulize.camelize.pluralize.freeze
          end

        else
          def default_model_path
            self.name
              .split('::').last                                             # .demodulize
              .gsub(/(\w)([A-Z])/) { [$1, '_', $2.downcase].join }.downcase # .camelize
              .sub(/y$/, 'ies').sub(/[^s]$/, '\0s')                         # .pluralize
                                                                            #  (poor man's)
          end
        end
      end
    end

  end
end

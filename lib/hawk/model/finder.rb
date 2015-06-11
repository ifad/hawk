module Hawk
  module Model

    module Finder
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def find(id_or_ids, params = {})
          if id_or_ids.respond_to?(:each)
            find_many(id_or_ids, params)
          else
            find_one(id_or_ids, params)
          end
        end

        def find_one(id, params = {})
          repr = connection.get(path_for(id, params), params)
          instantiate_one(repr, params.fetch(:options, {}))
        end

        def find_many(ids, params = {})
          repr = connection.post(path_for(batch_path, params), params.deep_merge(id: ids))
          instantiate_many(repr, params.fetch(:options, {}))
        end

        def all(params = {})
          repr = connection.get(path_for(nil, params), params)
          instantiate_many(repr, params.fetch(:options, {}))
        end

        def count(params = {})
          connection.get(path_for(count_path, params), params)
        end

        def path_for(component, params = {})
          [model_path_from(params), component].compact.join('/')
        end

        def instantiate_from(repr, http_options = {})
          if repr.is_a?(Array)
            instantiate_many(repr, http_options)
          else
            instantiate_one(repr, http_options)
          end
        end

        def instantiate_one(repr, http_options)
          repr = repr.fetch(instance_key) if repr.key?(instance_key)

          new repr, http_options
        end

        def instantiate_many(repr, http_options)
          if repr.respond_to?(:key?)
            collection  = repr.key?(collection_key) ? repr.fetch(collection_key)     : repr
            total_count = repr.key?('total_count')  ? repr.fetch('total_count').to_i : nil
          else
            collection  = repr
            total_count = repr.size
          end

          Collection.new(collection.map! {|repr| new(repr, http_options) }, total_count)
        end


        def instance_key
          @_instance_key ||= self.name.demodulize.underscore
        end

        def collection_key
          @_collection_key = instance_key.pluralize
        end

        def model_path_from(params)
          params.delete(:from) || model_path
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

        def batch_path(path = nil)
          @_batch_path = path if path
          @_batch_path ||= 'batch'
        end

        def count_path(path = nil)
          @_count_path = path if path
          @_count_path ||= 'count'
        end
      end
    end

  end
end

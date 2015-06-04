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
          instantiate_one connection.get([model_path_from(params), id].join('/'), params)
        end

        def find_many(ids, params = {})
          instantiate_many connection.post([model_path_from(params), batch_path].join('/'), params.merge(id: ids))
        end

        def all(params = {})
          instantiate_many connection.get(model_path_from(params), params)
        end

        def count(params = {})
          connection.get([model_path_from(params), count_path].join('/'), params)
        end


        def instantiate_one(repr)
          repr = repr.fetch(instance_key) if repr.key?(instance_key)

          new repr
        end

        def instantiate_many(repr)
          collection  = repr.key?(collection_key) ? repr.fetch(collection_key)     : repr
          total_count = repr.key?('total_count')  ? repr.fetch('total_count').to_i : nil

          Collection.new(collection.map! {|instance| new instance}, total_count)
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

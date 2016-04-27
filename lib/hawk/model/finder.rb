module Hawk
  module Model

    module Finder

      def self.included(base)
        base.extend ClassMethods
      end

      def path_for(component, params = {})
        [self.class.model_path_from(params), self.id, component].compact.join('/')
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
          instantiate_one(repr, params)
        end

        def find_many(ids, params = {})
          all(params.deep_merge(id: ids))
        end

        def all(params = {})
          path = path_for(nil, params)
          if connection.url_length(path,:get,params) > 2000
            path = path_for(batch_path, params)
            method = :post
          end
          repr = connection.send(method||:get, path, params)
          instantiate_many(repr, params)
        end

        def count(params = {})
          path = path_for(count_path, params)
          method = connection.url_length(path,:get,params) > 2000 ? :post : :get
          repr = connection.send(method, path, params)
          repr.fetch(count_key).to_i
        end

        def path_for(component, params = {})
          [model_path_from(params), component].compact.join('/')
        end

        def instantiate_from(repr, params = {})
          if repr.is_a?(Array)
            instantiate_many(repr, params)
          else
            instantiate_one(repr, params)
          end
        end

        def instantiate_many(repr, params)
          if repr.respond_to?(:key?)
            collection  = repr.key?(collection_key)  ? repr.fetch(collection_key)       : []
            total_count = repr.key?(total_count_key) ? repr.fetch(total_count_key).to_i : nil
          else
            collection  = repr
            total_count = nil
          end

          collection_options = {
            limit:       params[limit_param],
            offset:      params[offset_param],
            total_count: total_count
          }

          Collection.new(collection.map! {|repr| instantiate_one(repr, params) }, collection_options)
        end

        def instantiate_one(repr, params)
          if repr.key?(instance_key) && (repr[instance_key].is_a?(Hash))
            repr = repr.fetch(instance_key)
          end

          new repr, params
        end

        def instance_key
          @_instance_key ||= self.name.demodulize.underscore
        end

        def collection_key
          @_collection_key = instance_key.pluralize
        end

        def total_count_key
          @_total_count_key = 'total_count'
        end

        def count_key
          @_count_key = 'count'
        end

        def limit_param
          :limit
        end

        def offset_param
          :offset
        end

        def model_path_from(params)
          if (from = params.fetch(:options, {}).fetch(:endpoint, nil))
            from = [model_path, from].join('/') unless from[0] == '/'
            from
          else
            model_path
          end
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

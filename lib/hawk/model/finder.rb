# frozen_string_literal: true

module Hawk
  module Model
    ##
    # Provides finder methods for locating records by ID or querying collections.
    # Handles path building, record instantiation, and collection wrapping.
    #
    # @example Finding a single record
    #   post = Post.find(1)
    #
    # @example Finding multiple records
    #   posts = Post.find([1, 2, 3])
    #
    # @example Getting all records
    #   posts = Post.all
    #
    # @example Getting a count
    #   count = Post.count
    #
    module Finder
      ##
      # Extends the including model with class-level finder methods.
      #
      # @param base [Class] the model class including the finder helpers
      def self.included(base)
        base.extend ClassMethods
      end

      ##
      # Builds the URL path for this model instance.
      #
      # @param component [String, nil] optional path component
      # @param params [Hash] additional parameters
      # @return [String] the full URL path
      def path_for(component, params = {})
        [self.class.model_path_from(params), id, component].compact.join('/')
      end

      ##
      # Class-level record lookup and instantiation helpers.
      module ClassMethods
        ##
        # Finds a record or multiple records by ID(s).
        #
        # @param id_or_ids [Integer, Array<Integer>] one or more record IDs
        # @param params [Hash] additional query parameters
        # @return [Base, Collection, nil] the found record(s)
        #
        # @example Finding a single record
        #   post = Post.find(1)
        #
        # @example Finding multiple records
        #   posts = Post.find([1, 2, 3])
        def find(id_or_ids, params = {})
          if id_or_ids.respond_to?(:each)
            find_many(id_or_ids, params)
          else
            find_one(id_or_ids, params)
          end
        end

        ##
        # Finds a single record by ID.
        #
        # @param id [Integer] the record ID
        # @param params [Hash] additional query parameters
        # @return [Base] the found record
        # @raise [Hawk::Error::NotFound] if the record is not found
        def find_one(id, params = {})
          repr = connection.get(path_for(id, params), params)
          instantiate_one(repr, params)
        end

        ##
        # Finds multiple records by IDs using a batch query.
        #
        # @param ids [Array<Integer>] the record IDs
        # @param params [Hash] additional query parameters
        # @return [Collection] the found records
        def find_many(ids, params = {})
          all(params.deep_merge(id: ids))
        end

        ##
        # Returns all records, optionally with query parameters.
        #
        # @param params [Hash] query parameters
        # @return [Collection] all records
        #
        # @example Getting all records
        #   posts = Post.all
        #
        # @example With filters
        #   posts = Post.all(published: true)
        def all(params = {})
          path = path_for(nil, params)
          if connection.url_length(path, :get, params) > 2000
            path = path_for(batch_path, params)
            method = :post
          end
          repr = connection.send(method || :get, path, params)
          instantiate_many(repr, params)
        end

        ##
        # Returns the count of records, optionally with query parameters.
        #
        # @param params [Hash] query parameters
        # @return [Integer] the record count
        #
        # @example Getting a count
        #   count = Post.count
        #
        # @example With filters
        #   count = Post.count(published: true)
        def count(params = {})
          params = {} unless params.is_a?(Hash)
          path = path_for(count_path, params)
          method = connection.url_length(path, :get, params) > 2000 ? :post : :get
          repr = connection.send(method, path, params)
          repr.fetch(count_key).to_i
        end

        ##
        # Builds the URL path for this model class.
        #
        # @param component [String, nil] optional path component
        # @param params [Hash] additional parameters
        # @return [String] the full URL path
        def path_for(component, params = {})
          [model_path_from(params), component].compact.join('/')
        end

        ##
        # Instantiates one or many records from a representation.
        #
        # @param repr [Hash, Array] the record representation(s)
        # @param params [Hash] additional parameters
        # @return [Base, Collection] the instantiated record(s)
        def instantiate_from(repr, params = {})
          if repr.is_a?(Array)
            instantiate_many(repr, params)
          else
            instantiate_one(repr, params)
          end
        end

        ##
        # Instantiates multiple records from an array representation.
        #
        # @param repr [Array, Hash] the records representation
        # @param params [Hash] additional parameters
        # @return [Collection] the instantiated records
        def instantiate_many(repr, params)
          if repr.respond_to?(:key?)
            collection  = repr.key?(collection_key)  ? repr.fetch(collection_key)       : []
            total_count = repr.key?(total_count_key) ? repr.fetch(total_count_key).to_i : nil
          else
            collection  = repr
            total_count = nil
          end

          collection_options = {
            limit: params[limit_param],
            offset: params[offset_param],
            total_count: total_count
          }

          Collection.new(collection.map! { |repr| instantiate_one(repr, params) }, collection_options)
        end

        ##
        # Instantiates a single record from its representation.
        #
        # @param repr [Hash] the record representation
        # @param params [Hash] additional parameters
        # @return [Base] the instantiated record
        def instantiate_one(repr, params)
          if repr.key?(instance_key) && repr[instance_key].is_a?(Hash)
            repr = repr.fetch(instance_key)
          end

          new repr, params
        end

        ##
        # Returns the instance key (singularized class name).
        #
        # @return [String] the instance key
        def instance_key
          @instance_key ||= name.demodulize.underscore
        end

        ##
        # Returns the collection key (pluralized class name).
        #
        # @return [String] the collection key
        def collection_key
          @collection_key = instance_key.pluralize
        end

        ##
        # Returns the total count key for pagination.
        #
        # @return [String] the total count key
        def total_count_key
          @total_count_key = 'total_count'
        end

        ##
        # Returns the count key for count queries.
        #
        # @return [String] the count key
        def count_key
          @count_key = 'count'
        end

        ##
        # Returns the limit parameter name.
        #
        # @return [Symbol] the limit parameter name
        def limit_param
          :limit
        end

        ##
        # Returns the offset parameter name.
        #
        # @return [Symbol] the offset parameter name
        def offset_param
          :offset
        end

        ##
        # Returns the model path, considering any endpoint override.
        #
        # @param params [Hash] query parameters
        # @return [String] the model path
        def model_path_from(params)
          if (from = params.dig(:options, :endpoint))
            from = [model_path, from].join('/') unless from[0] == '/'
            from
          else
            model_path
          end
        end

        ##
        # Sets or returns the base path for this model's API endpoint.
        #
        # @param path [String, nil] the path to set
        # @return [String] the model path
        # @raise [Hawk::Error::Configuration] if called on Hawk::Model::Base
        def model_path(path = nil)
          if self == Hawk::Model::Base
            raise Error::Configuration, "Hawk's Base class doesn't have any path"
          end

          @model_path = path if path
          @model_path ||= default_model_path
        end

        ##
        # Returns the default model path based on the class name.
        #
        # @return [String] the default model path
        def default_model_path
          name.demodulize.underscore.pluralize.freeze
        end

        ##
        # Sets or returns the batch path for batch queries.
        #
        # @param path [String, nil] the path to set
        # @return [String] the batch path
        def batch_path(path = nil)
          @batch_path = path if path
          @batch_path ||= 'batch'
        end

        ##
        # Sets or returns the count path for count queries.
        #
        # @param path [String, nil] the path to set
        # @return [String] the count path
        def count_path(path = nil)
          @count_path = path if path
          @count_path ||= 'count'
        end
      end
    end
  end
end

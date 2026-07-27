# frozen_string_literal: true

module Hawk
  module Model
    ##
    # Provides ActiveRecord-like querying methods for Hawk models.
    # Supports chaining methods like `where`, `limit`, `offset`, `order`,
    # and `includes` through a Proxy object.
    #
    # @example Chaining queries
    #   posts = Post.where(published: true).order(:created_at).limit(10)
    #
    # @example Using scopes
    #   class Post < Hawk::Model::Base
    #     scope :published, -> { where(published: true) }
    #     scope :recent, -> { order(:created_at).limit(10) }
    #   end
    #
    #   posts = Post.published.recent
    #
    module Querying
      ##
      # Extends the including model with class-level query builders.
      #
      # @param base [Class] the model class including the querying helpers
      def self.included(base)
        base.extend ClassMethods
      end

      ##
      # Class-level query helper methods that return Proxy instances.
      module ClassMethods
        ##
        # Returns an empty proxy that will not fetch any records.
        #
        # @return [Proxy::Void] an empty proxy
        #
        # @example
        #   Post.none # => []
        def none
          Proxy::Void.new(self, {})
        end

        ##
        # Returns a proxy with the given query parameters.
        #
        # @param params [Hash] query parameters
        # @return [Proxy] a new proxy with the given params
        #
        # @example
        #   posts = Post.where(published: true)
        #   posts.all # => [...]
        def where(params)
          Proxy.new(self, params)
        end

        ##
        # Returns a proxy with the default params merged with the given params.
        #
        # @param params [Hash] additional query parameters
        # @return [Proxy] a new proxy
        def scoped(params = {})
          where(default_params.deep_merge(params))
        end

        ##
        # Returns all records, merging default params with the given params.
        #
        # @param params [Hash] additional query parameters
        # @return [Collection] all matching records
        def all(params = {})
          super(default_params.deep_merge(params))
        end

        ##
        # Sets or returns the default params for this model class.
        #
        # @param params [Hash, nil] default params to set
        # @return [Hash] the default params
        def default_params(params = nil)
          @default_params = params if params
          @default_params ||= {}
        end

        ##
        # Returns a proxy with the given limit.
        #
        # @param value [Integer] the maximum number of records to return
        # @return [Proxy] a new proxy with the limit
        #
        # @example
        #   posts = Post.limit(10)
        def limit(value)
          where(limit_param => value)
        end

        ##
        # Returns a proxy with the given offset.
        #
        # @param value [Integer] the number of records to skip
        # @return [Proxy] a new proxy with the offset
        #
        # @example
        #   posts = Post.offset(20)
        def offset(value)
          where(offset_param => value)
        end

        ##
        # Returns a proxy with the given order.
        #
        # @param by [String, Symbol] the column to order by
        # @return [Proxy] a new proxy with the order
        #
        # @example
        #   posts = Post.order(:created_at)
        def order(by)
          where(order: by)
        end

        ##
        # Returns a proxy that includes the specified associations.
        #
        # @param what [String, Symbol, Array] the associations to include
        # @return [Proxy] a new proxy with includes
        #
        # @example
        #   posts = Post.includes(:comments)
        def includes(what)
          where(includes: what)
        end

        ##
        # Returns a proxy with the given options.
        #
        # @param opts [Hash] additional options
        # @return [Proxy] a new proxy with the options
        #
        # @example
        #   posts = Post.options(endpoint: 'featured')
        def options(opts)
          where(options: opts)
        end

        ##
        # Returns a proxy with basic authentication credentials.
        #
        # @param username [String] the username
        # @param password [String] the password
        # @return [Proxy] a new proxy with auth credentials
        #
        # @example
        #   posts = Post.auth('user', 'pass')
        def auth(username, password)
          options(username: username, password: password)
        end

        ##
        # Returns a proxy with a custom endpoint.
        #
        # @param path [String] the endpoint path
        # @return [Proxy] a new proxy with the endpoint
        #
        # @example
        #   posts = Post.from('featured')
        def from(path)
          options(endpoint: path)
        end

        ##
        # Returns the first record with a limit of 1.
        #
        # @param params [Hash] additional query parameters
        # @return [Base, nil] the first record, or nil if not found
        #
        # @example
        #   post = Post.first
        #   post = Post.find_by(published: true)
        def first(params = {})
          limit(1).first(params)
        end
        alias find_by first

        ##
        # Returns the first record or raises NotFound if not found.
        #
        # @param params [Hash] additional query parameters
        # @return [Base] the first record
        # @raise [Hawk::Error::NotFound] if no record is found
        #
        # @example
        #   post = Post.first!
        #   post = Post.find_by!(published: true)
        def first!(params = {})
          first(params) or raise(Hawk::Error::NotFound, "Can't find first #{self}")
        end
        alias find_by! first!
      end
    end
  end
end

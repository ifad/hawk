# frozen_string_literal: true

module Hawk
  module Model
    ##
    # A proxy object that lazily loads and chains query parameters for
    # Hawk models. Supports ActiveRecord-like query methods and provides
    # an Enumerable interface for iterating over results.
    #
    # @example Chaining queries
    #   posts = Post.where(published: true).order(:created_at).limit(10)
    #   posts.each { |post| puts post.title }
    #
    # @example Using as an Enumerable
    #   post_titles = Post.where(published: true).map(&:title)
    #
    class Proxy
      include Enumerable

      ##
      # Initializes a new proxy for the given class with the given params.
      #
      # @param klass [Class] the model class
      # @param params [Hash] query parameters
      def initialize(klass, params)
        @klass   = klass
        @params  = params
        @result  = nil
      end

      ##
      # A void proxy that returns empty results without making any HTTP requests.
      #
      # @example
      #   Post.none # => Proxy::Void
      #   Post.none.to_a # => []
      class Void < self
        ##
        # @param klass [Class] the model class
        # @param params [Hash] query parameters
        def initialize(klass, params)
          super
          @params[:void] = true # Only for reporting purposes
          @result = []
        end

        ##
        # Always returns nil for void proxies.
        #
        # @return [nil]
        def find(*)
          nil
        end

        ##
        # Always returns 0 for void proxies.
        #
        # @return [Integer] always 0
        def count(*)
          0
        end
      end

      ##
      # Returns the model class for this proxy.
      #
      # @return [Class] the model class
      attr_reader :klass, :params

      ##
      # Returns a new proxy with the given params merged.
      #
      # @param params [Hash] query parameters to merge
      # @return [Proxy] a new proxy with merged params
      #
      # @example
      #   posts = Post.where(published: true).where(author: 'John')
      def where(params)
        self.class.new klass, @params.deep_merge(params)
      end

      ##
      # Finds a record or multiple records by ID(s).
      #
      # @param id_or_ids [Integer, Array<Integer>] one or more record IDs
      # @param params [Hash] additional query parameters
      # @return [Base, Collection, nil] the found record(s)
      def find(id_or_ids, params = {})
        @result = klass.find(id_or_ids, @params.deep_merge(params))
      end

      ##
      # Returns all records matching the current query parameters.
      #
      # @param params [Hash] additional query parameters
      # @return [Collection] all matching records
      def all(params = {})
        @result ||= klass.all(@params.deep_merge(params))
      end
      alias result all

      ##
      # Returns the first record matching the current query parameters.
      #
      # @param params [Hash] additional query parameters
      # @return [Base, nil] the first record, or nil if not found
      def first(params = {})
        limit(1).all(params).first
      end
      alias find_by first

      ##
      # Returns the first record or raises NotFound.
      #
      # @param params [Hash] additional query parameters
      # @return [Base] the first record
      # @raise [Hawk::Error::NotFound] if no record is found
      def first!(params = {})
        first(params) or raise Hawk::Error::NotFound, "Can't find #{klass} with #{params.to_json}"
      end
      alias find_by! first!

      ##
      # Returns the limit value from the query parameters.
      #
      # @return [Integer] the limit value
      def limit_value
        params[klass.limit_param].to_i
      end

      ##
      # Returns the offset value from the query parameters.
      #
      # @return [Integer] the offset value
      def offset_value
        params[klass.offset_param].to_i
      end

      ##
      # Returns the count of matching records.
      #
      # @return [Integer] the record count
      def count(*)
        if @result
          @result.count
        else
          klass.count(params)
        end
      end

      ##
      # Iterates over all matching records.
      #
      # @yield [record] each matching record
      def each(*args, &block)
        all.each(*args, &block)
      end

      ##
      # Checks if the proxy responds to the given method.
      #
      # @param meth [Symbol] the method name
      # @param include_all [Boolean] whether to include private methods
      # @return [Boolean] true if the proxy responds to the method
      def respond_to?(meth, include_all = false)
        super ||
          klass.respond_to?(meth, include_all) ||
          result.respond_to?(meth, include_all)
      end

      protected

      ##
      # Delegates unknown methods to the model class or result.
      #
      # @param meth [Symbol] the method name
      # @param args [Array] method arguments
      # @param block [Proc] optional block
      # @return [Object] the method result
      def method_missing(meth, *args, &block)
        if klass.respond_to?(meth)

          method = klass.method(meth)
          dsl_method =
            if method.owner.respond_to?(:module_parents)
              method.owner.module_parents.include?(Hawk::Model)
            else
              method.owner.parents.include?(Hawk::Model)
            end

          # If the method accepts a variable number of parameters, and
          # exactly one is missing, push the scoped params at the end.
          if !dsl_method && (method.arity + args.size) == -1
            args = args.push params

          # If the method accepts a variable number of parameters, and
          # the last provided one is an hash, merge the scoped params.
          elsif method.arity < 0 && (method.arity + args.size) == 0 && args.last.is_a?(Hash)
            args[-1] = params.deep_merge(args[-1])

          end

          retval = klass.public_send(meth, *args, &block)
          if retval.is_a?(Proxy)
            merge(retval)
          else
            retval
          end
        elsif result.respond_to?(meth)
          result.public_send(meth, *args, &block)
        else
          super
        end
      end

      private

      ##
      # Merges another proxy's parameters into this one.
      #
      # @param other [Proxy] the other proxy to merge
      # @return [Proxy] this proxy with merged parameters
      def merge(other)
        target = other.is_a?(Void) ? to_void : self
        target.where(other.params)
      end

      ##
      # Converts this proxy to a void proxy.
      #
      # @return [Void] a void proxy with the same parameters
      def to_void
        Void.new(klass, params)
      end
    end
  end
end

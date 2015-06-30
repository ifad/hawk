module Hawk
  module Model

    class Proxy
      include Enumerable

      using Hawk::Polyfills # Hash#deep_merge, Module#parents

      def initialize(klass, params)
        @klass   = klass
        @params  = params
        @result  = nil
      end

      class Void < self
        def initialize(klass, params)
          super
          @params[:void] = true # Only for reporting purposes
        end

        def result
          []
        end

        def count
          0
        end
      end

      attr_reader :klass, :params

      def where(params)
        self.class.new klass, @params.deep_merge(params)
      end

      def find(id_or_ids, params = {})
        @result = klass.find(id_or_ids, @params.deep_merge(params))
      end

      def all(params = {})
        @result ||= klass.all(@params.deep_merge(params))
      end
      alias result all

      def first(params = {})
        limit(1).all(params).first
      end

      def first!(params = {})
        first(params) or raise Hawk::Error::NotFound, "Can't find #{klass} with #{params.to_json}"
      end

      def limit_value
        params[klass.limit_param]
      end

      def offset_value
        params[klass.offset_param].to_i
      end

      def count
        if @result
          @result.count
        else
          klass.count(params)
        end
      end

      def each(*args, &block)
        all.each(*args, &block)
      end

      def respond_to?(meth)
        super ||
          klass.respond_to?(meth) ||
          result.respond_to?(meth)
      end

      protected
        def method_missing(meth, *args, &block)
          if klass.respond_to?(meth)

            method = klass.method(meth)
            dsl_method = method.owner.parents.include?(Hawk::Model)

            # If the method accepts a variable number of parameters, and
            # exactly one is missing, push the scoped params at the end.
            if !dsl_method && (method.arity + args.size) == -1
              args = args.push params

            # If the method accepts a variable number of parameters, and
            # the last provided one is an hash, merge the scoped params.
            elsif method.arity < 0 && (method.arity + args.size == 0) && args.last.is_a?(Hash)
              args[-1] = params.deep_merge(args[-1])

            end

            retval = klass.public_send(meth, *args, &block)
            if retval.kind_of?(Proxy)
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
        def merge(other)
          target = other.is_a?(Void) ? to_void : self
          target.where(other.params)
        end

        def to_void
          Void.new(klass, params)
        end
    end

  end
end

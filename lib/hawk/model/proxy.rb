module Hawk
  module Model

    class Proxy
      include Enumerable

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
        params = params.reject {|_,v| v.nil?}
        self.class.new klass, @params.merge(params)
      end

      def find(id_or_ids)
        @result = klass.find(id_or_ids, params)
      end

      def all
        @result ||= klass.all(params)
      end
      alias result all

      def first
        limit(1).all.first
      end

      def first!
        first or raise Hawk::Error::NotFound, "Can't find #{klass} with #{params.to_json}"
      end

      def limit_value
        params[:limit]
      end

      def offset_value
        params[:offset]
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
          collection.respond_to?(meth)
      end

      protected
        def method_missing(meth, *args, &block)
          if klass.respond_to?(meth)
            retval = klass.public_send(meth, *args, &block)
            if retval.kind_of?(Proxy)
              merge(retval)
            else
              retval
            end
          elsif collection.respond_to?(meth)
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

        def collection
          @_collection ||= Collection.new
        end
    end

  end
end

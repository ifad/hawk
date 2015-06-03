module Hawk
  module Model

    module Querying
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        # Returns an empty +Proxy+
        #
        def none
          Proxy::Void.new(self, {})
        end

        # Returns a +Proxy+ with the given params
        #
        def where(params)
          Proxy.new(self, params)
        end

        # Returns a +Proxy+ with empty params
        #
        def scoped
          where(default_params)
        end

        def all(params = {})
          super(default_params(params))
        end

        def default_params(*)
          {}
        end

        # Adds `limit` with the given number of records
        #
        def limit(n)
          where(limit: n)
        end

        # Adds an `offset` with the given number of records
        #
        def offset(n)
          where(offset: n)
        end

        # Adds a limit(1) and returns the first record
        #
        def first
          limit(1).first
        end

        # Looks for the first record or raises a
        # +ActiveResource::ResourceNotFound+ if not found
        #
        def first!
          first or raise Hawk::Error::NotFound.new("Can't find first #{self}")
        end
      end
    end

  end
end

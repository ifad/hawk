# frozen_string_literal: true

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

        # Returns a +Proxy+ with the default params
        #
        def scoped(params = {})
          where(default_params.deep_merge(params))
        end

        def all(params = {})
          super(default_params.deep_merge(params))
        end

        def default_params(params = nil)
          @default_params = params if params
          @default_params ||= {}
        end

        # Adds +limit+ with the given number of records
        #
        def limit(n)
          where(limit_param => n)
        end

        # Adds an +offset+ with the given number of records
        #
        def offset(n)
          where(offset_param => n)
        end

        def order(by)
          where(order: by)
        end

        def includes(what)
          where(includes: what)
        end

        def options(opts)
          where(options: opts)
        end

        def auth(username, password)
          options(username: username, password: password)
        end

        def from(path)
          options(endpoint: path)
        end

        # Adds a limit(1) and returns the first record
        #
        def first(params = {})
          limit(1).first(params)
        end
        alias find_by first

        # Looks for the first record or raises a
        # {Hawk::Error::NotFound} if not found
        #
        def first!(params = {})
          first(params) or raise(Hawk::Error::NotFound, "Can't find first #{self}")
        end
        alias find_by! first!
      end
    end
  end
end

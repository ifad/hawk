module Hawk
  module Model

    ##
    # Fetches models from the remote HTTP endpoint.
    #
    module Connection
      def self.included(base)
        base.extend ClassMethods
      end

      def connection
        self.class.connection
      end

      module ClassMethods
        def connection
          raise Error::Configuration, "URL for #{name} is not yet set" unless url

          @_connection ||= Hawk::HTTP.new(url, http_options)
        end

        def url(url = nil)
          @_url = url.dup.freeze if url
          @_url
        end
        alias url= url

        def http_options(options = nil)
          @_http_options = options.dup.freeze if options
          @_http_options || {}
        end
        alias http_options= http_options

        def inherited(subclass)
          super

          subclass.url          = self.url
          subclass.http_options = self.http_options
        end
      end
    end

  end
end

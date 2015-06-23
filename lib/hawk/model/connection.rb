module Hawk
  module Model

    ##
    # Fetches models from the remote HTTP endpoint.
    #
    module Connection
      def self.included(base)
        base.extend ClassMethods
      end

      def initialize(attributes = {}, http_options = {})
        @http_options = http_options || {}

        super
      end
      attr_reader :http_options

      def connection
        self.class.connection
      end

      module ClassMethods
        def connection
          @_connection ||= begin
            raise Error::Configuration, "URL for #{name} is not yet set" unless url
            raise Error::Configuration, "Please set the client_name"     unless client_name

            options = self.http_options.dup
            headers = (options[:headers] ||= {})
            headers['User-Agent'] = self.client_name

            Hawk::HTTP.new(url, options)
          end
        end

        def url(url = nil)
          @_url = url.dup.freeze if url

          configurable.each {|model| model.url = @_url }

          return @_url
        end
        alias url= url

        def http_options(options = nil)
          @_http_options = options.dup.freeze if options
          @_http_options ||= {}

          configurable.each {|model| model.http_options = @_http_options }

          return @_http_options
        end
        alias http_options= http_options

        def client_name(name = nil)
          @_client_name = name.dup.freeze if name

          configurable.each {|model| model.client_name = @_client_name }

          return @_client_name
        end
        alias client_name= client_name

        def inherited(subclass)
          super

          subclass.url          = self.url
          subclass.http_options = self.http_options
          subclass.client_name  = self.client_name
        end
      end
    end

  end
end

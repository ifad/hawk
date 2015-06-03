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
          @_connection ||= begin
            raise Error::Configuration, "URL for #{name} is not yet set" unless url
            raise Error::Configuration, "Please set the client_name"     unless client_name

            options = self.http_options.dup
            headers = (options[:headers] ||= {})

            if headers.key?('User-Agent')
              raise Error::Configuration, "Please set the User-Agent header through client_name"
            end

            headers['User-Agent'] = self.client_name

            Hawk::HTTP.new(url, options)
          end
        end

        def url(url = nil)
          @_url = url.dup.freeze if url
          @_url
        end
        alias url= url

        def http_options(options = nil)
          @_http_options = options.dup.freeze if options
          @_http_options ||= {}
        end
        alias http_options= http_options

        def client_name(name = nil)
          @_client_name = name.dup.freeze if name
          @_client_name
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

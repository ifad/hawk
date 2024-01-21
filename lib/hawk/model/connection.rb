module Hawk
  module Model
    ##
    # Fetches models from the remote HTTP endpoint.
    #
    module Connection
      def self.included(base)
        base.extend ClassMethods
      end

      def initialize(attributes = {}, params = {})
        @params = params || {}

        super
      end
      attr_reader :params

      def connection
        self.class.connection
      end

      # These methods delegate to connection and path_for, but are
      # included in both the instance and the class, and in both
      # cases they reference the specialized implementation of
      # path_for, class- or instance- level.
      #
      module SharedMethods
        def get(component, params = {})
          connection.get(path_for(component), params)
        end

        def raw_get(component, params = {})
          connection.raw_get(path_for(component), params)
        end

        def post(component, params = {})
          connection.post(path_for(component), params)
        end

        def raw_post(component, params = {})
          connection.raw_post(path_for(component), params)
        end

        def put(component, params = {})
          connection.put(path_for(component), params)
        end

        def raw_put(component, params = {})
          connection.raw_put(path_for(component), params)
        end

        def patch(component, params = {})
          connection.patch(path_for(component), params)
        end

        def raw_patch(component, params = {})
          connection.raw_patch(path_for(component), params)
        end

        def delete(component, params = {})
          connection.delete(path_for(component), params)
        end

        def raw_delete(component, params = {})
          connection.raw_delete(path_for(component), params)
        end
      end

      include SharedMethods

      module ClassMethods
        include SharedMethods

        def connection
          @_connection ||= begin
            raise Error::Configuration, "URL for #{name} is not yet set" unless url
            raise Error::Configuration, 'Please set the client_name'     unless client_name

            options = http_options.dup
            headers = (options[:headers] ||= {})
            headers['User-Agent'] = client_name

            Hawk::HTTP.new(url, options)
          end
        end

        def url(url = nil)
          @_url = url.dup.freeze if url

          configurable.each { |model| model.url = @_url }

          @_url
        end
        alias url= url

        def http_options(options = nil)
          @_http_options ||= {}

          if options
            @_http_options = @_http_options.deep_merge(options.dup).freeze
          end

          configurable.each { |model| model.http_options = @_http_options }

          @_http_options
        end
        alias http_options= http_options

        def client_name(name = nil)
          @_client_name = name.dup.freeze if name

          configurable.each { |model| model.client_name = @_client_name }

          @_client_name
        end
        alias client_name= client_name

        def inherited(subclass)
          super

          subclass.url          = url
          subclass.http_options = http_options
          subclass.client_name  = client_name
        end
      end
    end
  end
end

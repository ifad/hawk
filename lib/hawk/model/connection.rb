# frozen_string_literal: true

module Hawk
  module Model
    ##
    # Provides HTTP connection management for Hawk models. Handles
    # URL configuration, HTTP options, and client naming.
    #
    # @example Configuring a model's connection
    #   class Post < Hawk::Model::Base
    #     url 'https://api.example.com/'
    #     client_name 'MyApp/1.0'
    #     http_options timeout: 30
    #   end
    #
    module Connection
      ##
      # Extends the including model with class-level connection helpers.
      #
      # @param base [Class] the model class including the connection helpers
      def self.included(base)
        base.extend ClassMethods
      end

      ##
      # Initializes the model with connection parameters.
      #
      # @param attributes [Hash] model attributes
      # @param params [Hash] additional parameters for associations
      def initialize(attributes = {}, params = {})
        @params = params || {}

        super
      end

      ##
      # Returns the parameters hash for this model instance.
      #
      # @return [Hash] the model parameters
      attr_reader :params

      ##
      # Returns the HTTP connection for this model class.
      #
      # @return [Hawk::HTTP] the HTTP connection
      def connection
        self.class.connection
      end

      ##
      # Shared HTTP methods that delegate to the connection. These methods
      # are included in both instance and class contexts.
      #
      module SharedMethods
        ##
        # Performs a GET request through the connection.
        #
        # @param component [String] URL path component
        # @param params [Hash] query parameters
        # @return [Object] parsed JSON response
        def get(component, params = {})
          connection.get(path_for(component), params)
        end

        ##
        # Performs a raw GET request through the connection.
        #
        # @param component [String] URL path component
        # @param params [Hash] query parameters
        # @return [String] raw response body
        def raw_get(component, params = {})
          connection.raw_get(path_for(component), params)
        end

        ##
        # Performs a POST request through the connection.
        #
        # @param component [String] URL path component
        # @param params [Hash] request body parameters
        # @return [Object] parsed JSON response
        def post(component, params = {})
          connection.post(path_for(component), params)
        end

        ##
        # Performs a raw POST request through the connection.
        #
        # @param component [String] URL path component
        # @param params [Hash] request body parameters
        # @return [String] raw response body
        def raw_post(component, params = {})
          connection.raw_post(path_for(component), params)
        end

        ##
        # Performs a PUT request through the connection.
        #
        # @param component [String] URL path component
        # @param params [Hash] request body parameters
        # @return [Object] parsed JSON response
        def put(component, params = {})
          connection.put(path_for(component), params)
        end

        ##
        # Performs a raw PUT request through the connection.
        #
        # @param component [String] URL path component
        # @param params [Hash] request body parameters
        # @return [String] raw response body
        def raw_put(component, params = {})
          connection.raw_put(path_for(component), params)
        end

        ##
        # Performs a PATCH request through the connection.
        #
        # @param component [String] URL path component
        # @param params [Hash] request body parameters
        # @return [Object] parsed JSON response
        def patch(component, params = {})
          connection.patch(path_for(component), params)
        end

        ##
        # Performs a raw PATCH request through the connection.
        #
        # @param component [String] URL path component
        # @param params [Hash] request body parameters
        # @return [String] raw response body
        def raw_patch(component, params = {})
          connection.raw_patch(path_for(component), params)
        end

        ##
        # Performs a DELETE request through the connection.
        #
        # @param component [String] URL path component
        # @param params [Hash] query parameters
        # @return [Object] parsed JSON response
        def delete(component, params = {})
          connection.delete(path_for(component), params)
        end

        ##
        # Performs a raw DELETE request through the connection.
        #
        # @param component [String] URL path component
        # @param params [Hash] query parameters
        # @return [String] raw response body
        def raw_delete(component, params = {})
          connection.raw_delete(path_for(component), params)
        end
      end

      include SharedMethods

      ##
      # Class-level connection configuration and request helpers.
      module ClassMethods
        include SharedMethods

        ##
        # Returns or creates the HTTP connection for this model class.
        #
        # @return [Hawk::HTTP] the HTTP connection
        # @raise [Hawk::Error::Configuration] if URL or client_name is not set
        def connection
          @connection ||= begin
            raise Error::Configuration, "URL for #{name} is not yet set" unless url
            raise Error::Configuration, 'Please set the client_name'     unless client_name

            options = http_options.dup
            headers = (options[:headers] ||= {})
            headers['User-Agent'] = client_name

            Hawk::HTTP.new(url, options)
          end
        end

        ##
        # Sets or returns the base URL for this model class.
        # When set, the URL is propagated to all configurable subclasses.
        #
        # @param url [String, nil] the base URL
        # @return [String, nil] the base URL
        def url(url = nil)
          @_url = url.dup.freeze if url

          configurable.each { |model| model.url = @_url }

          @_url
        end
        alias url= url

        ##
        # Sets or returns the HTTP options for this model class.
        # When set, options are propagated to all configurable subclasses.
        #
        # @param options [Hash, nil] HTTP options to merge
        # @return [Hash] the HTTP options
        def http_options(options = nil)
          @_http_options ||= {}

          if options
            @_http_options = @_http_options.deep_merge(options.dup).freeze
          end

          configurable.each { |model| model.http_options = @_http_options }

          @_http_options
        end
        alias http_options= http_options

        ##
        # Sets or returns the client name (User-Agent) for this model class.
        # When set, the name is propagated to all configurable subclasses.
        #
        # @param name [String, nil] the client name
        # @return [String, nil] the client name
        def client_name(name = nil)
          @_client_name = name.dup.freeze if name

          configurable.each { |model| model.client_name = @_client_name }

          @_client_name
        end
        alias client_name= client_name

        ##
        # Inherits connection settings from parent class.
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

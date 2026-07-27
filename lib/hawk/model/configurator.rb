# frozen_string_literal: true

module Hawk
  module Model
    ##
    # Provides configuration management for Hawk models and their subclasses.
    # Allows setting configuration options that propagate to all subclasses.
    #
    # @example Configuring a model
    #   class Base < Hawk::Model::Base
    #     url 'https://api.example.com/'
    #     client_name 'MyApp/1.0'
    #   end
    #
    #   # Configuration propagates to subclasses
    #   class Post < Base
    #     # Inherits URL and client_name from Base
    #   end
    #
    module Configurator
      ##
      # Extends the including model with class-level configuration helpers.
      #
      # @param base [Class] the model class including the configurator
      def self.included(base)
        base.extend ClassMethods
      end

      ##
      # Class-level configuration APIs.
      module ClassMethods
        ##
        # Configures the model class and all its subclasses.
        #
        # @yield [model] block to configure each model
        #
        # @example
        #   class Post < Hawk::Model::Base
        #     configure do
        #       url 'https://api.example.com/'
        #       client_name 'MyApp/1.0'
        #     end
        #   end
        def configure(&block)
          ([self] + configurable).each do |model|
            model.instance_eval(&block)
          end
        end

        ##
        # Tracks subclasses for configuration propagation.
        #
        # @param subclass [Class] the subclass
        def inherited(subclass)
          super

          (@_configurable ||= []) << subclass
        end

        protected

        ##
        # Returns all configurable subclasses (recursively).
        #
        # @return [Array<Class>] all subclasses that should receive configuration
        def configurable
          (@_configurable ||= []).inject(Set.new) do |s, klass|
            s.add klass
            s.merge klass.configurable
          end.to_a
        end
      end
    end
  end
end

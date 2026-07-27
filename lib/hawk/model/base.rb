# frozen_string_literal: true

module Hawk
  module Model
    ##
    # Represents a remote entity, wrapped into a model holding each property
    # in an instance variable, casting the JSON values to data types inferred
    # from the property names themselves.
    #
    # This is the primary base class for all Hawk models. It includes all
    # necessary modules for schema definition, HTTP connections, querying,
    # associations, and more.
    #
    # @example Defining a model
    #   class User < Hawk::Model::Base
    #     url 'https://api.example.com/'
    #     client_name 'MyApp/1.0'
    #
    #     schema do
    #       integer :id
    #       string :name, :email
    #       boolean :active
    #     end
    #
    #     has_many :posts
    #   end
    #
    # @example Using the model
    #   user = User.find(1)
    #   user.name   # => "John Doe"
    #   user.active # => true
    #
    # @see Hawk::Model::Schema
    # @see Hawk::Model::Connection
    # @see Hawk::Model::Finder
    # @see Hawk::Model::Querying
    class Base
      include Schema # First
      include Connection
      include Finder
      include Querying
      include Association
      include Pagination
      include Configurator
      include Lookup
      include Scoping
      include Active

      ##
      # Initializes a new model instance with the given attributes and params.
      #
      # @param attributes [Hash] attribute key-value pairs to initialize the model with
      # @param params [Hash] additional parameters to pass through to associations
      def initialize(attributes = {}, params = {})
        super
      end

      ##
      # Returns a string representation of the model instance, showing all
      # schema attributes and their values.
      #
      # @return [String] a human-readable representation
      def inspect
        result = "#<#{self.class.name}"

        schema.each_key do |k|
          result << " #{k}=#{read_attribute(k).inspect}"
        end

        result << '>'

        result
      end
    end
  end
end

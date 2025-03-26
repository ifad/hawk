# frozen_string_literal: true

module Hawk
  module Model
    ##
    # Represents a remote entity, wrapped into a model holding each property in
    # an instance variable, casting the JSON values to data types inferred from
    # the property names themselves.
    #
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

      def initialize(attributes = {}, params = {})
        super
      end

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

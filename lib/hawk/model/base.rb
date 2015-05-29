module Hawk
  module Model

    ##
    # Represents a remote entity, wrapped into a model holding each property in
    # an instance variable, casting the JSON values to data types inferred from
    # the property names themselves.
    #
    class Base
      include Schema
      include Persistence

      def initialize(attributes = {})
        super
      end
    end

  end
end

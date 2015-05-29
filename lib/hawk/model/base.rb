module Hawk
  module Model

    ##
    # Represents a remote entity, wrapped into a model holding each property in
    # an instance variable, casting the JSON values to data types inferred from
    # the property names themselves.
    #
    class Base
      include Schema
      include Connection

      def initialize(attributes = {})
        super
      end

      def inspect
        attributes = schema.inject('') {|s, (k,v)|
          s << " #{k}=#{read_attribute(k).inspect}"
        }
        "#<#{self.class.name}#{attributes}>"
      end
    end

  end
end

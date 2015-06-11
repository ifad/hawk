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

      def initialize(attributes = {}, http_options = {})
        super
      end

      def inspect
        attributes = schema.inject('') {|s, (k,v)|
          s << " #{k}=#{read_attribute(k).inspect}"
        }
        "#<#{self.class.name}#{attributes}>"
      end

      def self.configure(&block)
        instance_eval(&block)
      end
    end

  end
end

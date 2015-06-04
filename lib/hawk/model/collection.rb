module Hawk
  module Model

    class Collection < Array
      def initialize(elements = [], total_count = nil)
        self.replace(elements)
        @total_count = total_count
      end

      attr_reader :total_count

      def inspect
        "#<#{self.class.name} count:#{total_count} contents:#{super}>"
      end

      def count
        total_count || super
      end

      def map(&block)
        self.class.new(super, @total_count)
      end
    end

  end
end

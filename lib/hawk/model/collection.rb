module Hawk
  module Model

    class Collection < Array
      def initialize(elements = [], options = {})
        self.replace(elements)

        @total_count  = options[:total_count]
        @limit_value  = options[:limit]
        @offset_value = options[:offset].to_i
      end

      def inspect
        "#<#{self.class.name} count:#{total_count} contents:#{super}>"
      end

      attr_reader :total_count

      def limit_value
        @limit_value or raise Hawk::Error, "This collection is not paginated"
      end

      def offset_value
        @offset_value
      end

      def current_page
        limit_value == 0 ? 1 : (offset_value/limit_value)+1
      end

      def count
        total_count || super
      end

      def map(&block)
        self.class.new(super,
          total_count: @total_count,
          limit:       @limit_value,
          offset:      @offset_value
        )
      end
    end

  end
end

module Hawk
  module Model

    class Collection < Array
      include Kaminari::PageScopeMethods if defined? ::Kaminari

      def initialize(elements = [], http_options={})
        self.replace(elements)
        @total_count = http_options[:total_count]
        @limit_value = http_options[:limit]
        @offset_value = http_options[:offset]
      end

      attr_reader :total_count, :limit_value, :offset_value

      def inspect
        "#<#{self.class.name} count:#{total_count} contents:#{super}>"
      end

      def count
        total_count || super
      end

      def map(&block)
        self.class.new(super, total_count: @total_count, limit: @limit_value, offset: @offset_value)
      end
    end

  end
end

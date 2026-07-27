# frozen_string_literal: true

module Hawk
  module Model
    ##
    # A specialized Array subclass that holds a collection of Hawk model
    # instances with additional metadata like total count, limit, and offset
    # for pagination support.
    #
    # @example Working with collections
    #   posts = Post.all
    #   posts.total_count # => 100
    #   posts.limit_value # => 25
    #   posts.offset_value # => 0
    #
    #   posts.each { |post| puts post.title }
    #
    # @example Mapping preserves collection metadata
    #   titles = posts.map(&:title)
    #   titles.total_count # => 100
    #
    class Collection < Array
      ##
      # Initializes a new collection with the given elements and options.
      #
      # @param elements [Array] the collection elements
      # @param options [Hash] collection metadata
      # @option options [Integer] :total_count total number of records available
      # @option options [Integer] :limit the limit parameter used
      # @option options [Integer] :offset the offset parameter used
      def initialize(elements = [], options = {})
        replace(elements)

        @total_count  = options[:total_count]
        @limit_value  = options[:limit]
        @offset_value = options[:offset].to_i
      end

      ##
      # Returns a string representation of the collection.
      #
      # @return [String] a human-readable representation
      def inspect
        "#<#{self.class.name} count:#{total_count} contents:#{super}>"
      end

      ##
      # Returns the total count of records available (not just in this page).
      #
      # @return [Integer, nil] the total count, or nil if not paginated
      attr_reader :total_count, :offset_value

      ##
      # Returns the limit value used for this collection.
      #
      # @return [Integer] the limit value
      # @raise [Hawk::Error] if the collection is not paginated
      def limit_value
        @limit_value or raise Hawk::Error, 'This collection is not paginated'
      end

      ##
      # Returns the count of records in this collection, or total_count if available.
      #
      # @return [Integer] the record count
      def count
        total_count || super
      end

      ##
      # Maps the collection, preserving pagination metadata.
      #
      # @yield [element] each element in the collection
      # @return [Collection] a new collection with mapped elements
      def map(&block)
        self.class.new(super,
                       total_count: @total_count,
                       limit: @limit_value,
                       offset: @offset_value
                      )
      end
    end
  end
end

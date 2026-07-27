# frozen_string_literal: true

module Hawk
  module Model
    ##
    # Provides pagination support for Hawk models. Integrates with Kaminari
    # if available, otherwise provides basic pagination methods.
    #
    # @example Using pagination
    #   posts = Post.limit(25).offset(50)
    #   posts.current_page # => 3
    #
    # @example With Kaminari
    #   posts = Post.page(2).per(25)
    #   posts.total_count # => 100
    #   posts.current_page # => 2
    #
    module Pagination
      ##
      # Shared pagination helpers mixed into paginated proxies and collections.
      module Common
        ##
        # Returns the current page number based on offset and limit.
        #
        # @return [Integer] the current page number (1-indexed)
        def current_page
          if limit_value == 0
            1
          else
            (offset_value / limit_value) + 1
          end
        end
      end

      if defined?(::Kaminari)
        ##
        # Extends the including model with Kaminari-compatible pagination
        # helpers when Kaminari is available.
        #
        # @param base [Class] the model class including the pagination helpers
        def self.included(base)
          base.instance_eval do
            include Kaminari::ConfigurationMethods

            define_singleton_method Kaminari.config.page_method_name do |num = nil|
              limit(default_per_page).offset(default_per_page * ([num.to_i, 1].max - 1))
            end
          end
        end

        Proxy.instance_eval do
          include Kaminari::PageScopeMethods
          include Pagination::Common
        end

        Collection.instance_eval do
          include Kaminari::ConfigurationMethods::ClassMethods
          include Kaminari::PageScopeMethods
          include Pagination::Common
        end
      end
    end
  end
end

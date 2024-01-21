module Hawk
  module Model
    module Pagination
      module Common
        def current_page
          limit_value == 0 ? 1 : (offset_value / limit_value)+1
        end
      end

      if defined?(::Kaminari)
        def self.included(base)
          base.instance_eval do
            include Kaminari::ConfigurationMethods

            eval <<-RUBY
              def #{Kaminari.config.page_method_name}(num = nil)
                limit(default_per_page).
                offset(default_per_page * ([num.to_i, 1].max - 1))
              end
            RUBY
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

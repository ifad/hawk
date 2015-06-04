module Hawk
  module Model

    module Pagination
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

          Proxy.instance_eval do
            include Kaminari::PageScopeMethods
          end
        end
      end
    end

  end
end

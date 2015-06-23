module Hawk

  module Polyfills
    def self.polyfill(klass, method, &impl)
      unless klass.instance_methods.include?(method)
        refine(klass) do
          module_eval &impl
        end
      end
    end

    require 'hawk/polyfills/string'
    require 'hawk/polyfills/module'
    require 'hawk/polyfills/hash'
  end

end

module Hawk

  module Polyfills
    def self.polyfill(klass, method, &impl)
      unless klass.instance_methods.include? method
        klass.class_eval(&impl)
      end
    end

    require 'hawk/polyfills/string'
    require 'hawk/polyfills/module'
  end

end

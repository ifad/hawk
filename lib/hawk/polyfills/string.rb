module Hawk
  module Polyfills

    polyfill String, :demodulize do
      def demodulize
        self.split('::').last || self
      end
    end

    polyfill String, :underscore do
      def underscore
        self.gsub(/(\w)([A-Z])/) { [$1, '_', $2.downcase].join }.downcase
      end
    end

    polyfill String, :pluralize do
      def pluralize
        self.sub(/y$/, 'ies').sub(/[^s]$/, '\0s')
      end
    end

    polyfill String, :camelize do
      def camelize
        self.
          gsub(/(^\w)/) { $1.upcase }.
          gsub(/_(\w)/) { $1.upcase }
      end
    end

    polyfill String, :singularize do
      def singularize
        self.gsub(/s$/, '') # NAIVE
      end
    end

  end
end

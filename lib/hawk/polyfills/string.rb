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

  end
end

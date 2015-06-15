require 'English'

module Hawk
  module Polyfills

    polyfill Module, :parent do
      # Returns the name of the module containing this one.
      #
      #   M::N.parent_name # => "M"
      def parent_name
        @_parent_name ||= self.name =~ /::[^:]+\Z/ ? $PREMATCH : nil
      end

      def parent
        parent_name ? constantize(parent_name) : Object
      end

      def constantize(string)
        string.split('::').inject(Object) {|ns, c| ns.const_get(c)}
      end
    end

  end
end

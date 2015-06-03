module Hawk
  module Polyfills

    polyfill Module, :parent do
      # Returns the name of the module containing this one.
      #
      #   M::N.parent_name # => "M"
      def parent_name
        unless defined? @_parent_name
          @_parent_name = self.name =~ /::[^:]+\Z/ ? $PREMATCH.freeze : nil
        end
        @_parent_name
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

require 'English'

module Hawk
  module Polyfills

    polyfill Module, :parent do
      using Hawk::Polyfills

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

      def parents
        parents = []

        if parent_name
          parts = parent_name.split('::')

          until parts.empty?
            parents << constantize(parts * '::')
            parts.pop
          end
        end

        parents << Object unless parents.include? Object
        parents
      end
    end

  end
end

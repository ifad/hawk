module Hawk
  module Model

    ##
    # Fetches models from the remote HTTP endpoint.
    #
    module Persistence
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def url=(url)
          @url = url.dup.freeze
        end

        attr_reader :url

        def inherited(subclass)
          super
          subclass.url = self.url
        end
      end
    end

  end
end

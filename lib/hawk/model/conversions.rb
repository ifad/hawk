module Hawk
  module Model

    module Conversions
      def persisted?
        true # Naive, for now.
      end

      if false && defined?(ActiveModel)
        include ActiveModel::Conversion
      else
        def to_key
          persisted? ? [ self.id ] : nil
        end

        def to_model
          self
        end

        def to_param
          to_key.try(:join, '-')
        end
      end

     end
  end
end

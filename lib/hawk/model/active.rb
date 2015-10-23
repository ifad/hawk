require 'active_model/conversion'
require 'active_model/naming'
require 'active_model/translation'

module Hawk
  module Model

    module Active
      include ActiveModel::Conversion

      def self.included(base)
        base.extend ActiveModel::Naming
        base.extend ActiveModel::Translation
      end

      def persisted?
        true # Naive, for now.
      end
    end

  end
end

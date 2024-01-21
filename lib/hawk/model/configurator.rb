# frozen_string_literal: true

module Hawk
  module Model
    module Configurator
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def configure(&block)
          ([self] + configurable).each do |model|
            model.instance_eval(&block)
          end
        end

        def inherited(subclass)
          super

          (@_configurable ||= []) << subclass
        end

        protected

        def configurable
          (@_configurable ||= []).inject(Set.new) do |s, klass|
            s.add klass
            s.merge klass.configurable
          end.to_a
        end
      end
    end
  end
end

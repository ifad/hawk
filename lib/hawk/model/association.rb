module Hawk
  module Model

    module Association
      # Initialize the associations registry
      #
      def self.included(base)
        base.extend ClassMethods
        base.instance_eval { @_associations ||= {} }
      end

      module ClassMethods
        # Propagate associations to the subclasses on inheritance
        #
        def inherited(subclass)
          super

          parent = self
          subclass.instance_eval do
            @_associations ||= {}

            parent.associations.each do |name, (type, options)|
              _define_association(name, type, options)
            end
          end
        end

        # Return a copy of the associations registry
        #
        def associations
          @_associations.dup
        end

        # Check whether associations are defined
        #
        def associations?
          @_associations.present?
        end

        # Adds an has_many association, mimicking ActiveRecord's interface
        # TODO better documentation
        #
        def has_many(entities, options = {})
          entity = entities.to_s.singularize
          klass  = options[:class_name] || entity.camelize
          key    = options[:primary_key] || [self.name.demodulize.underscore, :id].join('_')
          from   = options[:from]
          # TODO params

          if from && from[0,4] != 'http'
            from = ['/', from].join unless from[0] == '/'
            from = [site, from].join
          end

          _define_association(entities, :has_many, class_name: klass, primary_key: key, from: from)
        end

        # Adds an has_one association, mimicking ActiveRecord's interface
        # TODO better documentation
        #
        def has_one(entity, options = {})
          entity = entity.to_s.singularize
          klass  = options[:class_name] || entity.camelize
          # TODO params

          _define_association(entity, :has_one, class_name: klass)
        end

        # Adds a belongs_to association, mimicking ActiveRecord's interface
        # TODO better documentation
        #
        def belongs_to(entity, options = {})
          if options[:polymorphic]
            polymorphic_belongs_to(entity, options)
          else
            monomorphic_belongs_to(entity, options)
          end
        end

        protected

        def monomorphic_belongs_to(entity, options)
          klass  = options[:class_name] || entity.to_s.camelize
          key    = options[:primary_key] || [entity, :id].join('_')
          params = options.fetch(:params, {})

          _define_association(entity, :monomorphic_belongs_to, class_name: klass, primary_key: key, params: params)
        end

        def polymorphic_belongs_to(entity, options)
          key = [options[:as] || entity, :id].join('_')
          # TODO params

          _define_association(entity, :polymorphic_belongs_to, as: key)
        end

        private

        def _define_association(name, type, options)
          @_associations[name] = [type, options]
          instance_exec(name, options, &ASSOCIATORS.fetch(type))
        end
      end
    end

  end
end

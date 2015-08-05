module Hawk
  module Model

    module Association
      using Hawk::Polyfills # Hash#deep_merge, Module#parent, String#demodulize, String#underscore, String#camelize, String#singularize

      # Initialize the associations registry
      #
      def self.included(base)
        base.extend ClassMethods
        base.instance_eval { @_associations ||= {} }
      end

      # Load associations early, to memoize them and avoid having
      # Hashes when a Model is more appropriate.
      #
      def initialize(attributes = {}, params = {})
        super
        if attributes.size > 0 && self.class.associations?
          preload_associations(attributes, params, self.class)
        end
      end

      private
        # Called to kick off the preloading of association objects from the response hash
        #
        def preload_associations(attributes, params, scope)
          self.instance_exec(scope, attributes, params, &scope.preload_association)
        end

        # Called by the subclass to instantiate an association object
        #
        def add_association_object(scope, name, repr)
          (type, options) = scope.associations[name.to_sym]
          if type
            target = scope.model_class_for(options.fetch(:class_name))
            result = target.instantiate_from(repr, params)
            set_or_add_association(name, type, result)
          else
            raise "Unhandled assocation: #{name}"
          end
        end

        # Returns true if the association type is a collection
        #
        def is_collection? type
          [ :polymorphic_belongs_to, :has_many ].include? type
        end

        # Returns the association variable name
        #
        def association_instance_variable name
          "@_#{name}"
        end

        # Returns true if the association has been previously assigned
        #
        def association_assigned? name
          instance_variable_defined?(association_instance_variable(name))
        end

        # Creates a blank assocation (empty collection or nil, depending on the type)
        #
        def instantiate_association name, type
          variable = association_instance_variable(name)
          return variable if association_assigned?(name)
          instance_variable_set( variable, is_collection?(type) ? Collection.new : nil )
          variable
        end

        # Sets an association value, or adds it to the collection, depending on
        # type
        #
        def set_or_add_association name, type, value
          variable = instantiate_association( name, type )
          if is_collection?(type)
            collection = instance_variable_get(variable)
            value.respond_to?(:each) ? collection.concat(value) : collection.push(value)
          else
            instance_variable_set(variable, value)
          end
        end

        # Removes inherited parameters (e.g. filter constraints) to stop them
        # tramping into association gets
        #
        def clean_inherited_params inherited, opts={}
          rv = {}.deep_merge opts
          rv[:options] = inherited[:options] if inherited && inherited[:options]
          rv
        end

      module ClassMethods
        # Propagate associations to the subclasses on inheritance
        #
        def inherited(subclass)
          super

          parent = self
          subclass.instance_eval do
            # Inherit associations
            @_associations ||= {}

            parent.associations.each do |name, (type, options)|
              _define_association(name, type, options)
            end

            # Inherit association preloading behaviour
            preload_association(&parent.preload_association)
          end
        end

        # Defines how associations should be preloaded.
        #
        # The given block gets called with the Hash returned in the client
        # request. The block's task is to identify all association Hashes
        # within the request and call "add_association_object", passing in
        # the scope, the association name and the association Hash.
        #
        # Please note: the "name" parameter should be the association name,
        # which means it must be pluralised for has_many and polymorphic
        # belongs_to
        #
        # Example (for Marcello :-)
        #
        #     class Foo < Hawk::Model::Base
        #
        #       has_many :bars
        #
        #       preload_association do |scope, attributes, params|
        #         attributes['linked_objects'].each do |object|
        #           add_association_object(scope, object['type'], object)
        #         end
        #       end
        #
        #     end
        #
        # The block would get called once, with Foo as scope, attributes being
        # the response Hash, and params holding the query parameters, which
        # is useful if you wish to check params[:includes] to set those
        # associations only.
        #
        # The default implementation of preload_association will look for all
        # attribute elements named after the association (e.g.
        # attributes['bars']) and call add_association_object with that value,
        # deleting it from the Hash.
        #
        def preload_association(&block)
          @_preload_association = block if block
          @_preload_association ||= lambda do |scope, attributes, params|
            if scope.associations?
              scope.associations.each_key do |name|
                attr = name.to_s
                next unless attributes.key?(attr)

                repr = attributes.delete(attr)
                add_association_object(scope, name, repr)
              end
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
          @_associations && @_associations.size > 0
        end

        # Check whether the given attribute is an association
        #
        def association?(attribute)
          @_associations.key?(attribute.to_sym)
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

          _define_association(entities, :has_many, class_name: klass, primary_key: key, from: from)
        end

        # Adds an has_one association, mimicking ActiveRecord's interface
        # TODO better documentation
        #
        def has_one(entity, options = {})
          entity = entity.to_s.singularize
          klass  = options[:class_name] || entity.camelize
          key    = options[:primary_key] || [self.name.demodulize.underscore, :id].join('_')
          from   = options[:from]
          # TODO params

          _define_association(entity, :has_one, class_name: klass, primary_key: key, from: from)
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
          @_associations[name.to_sym] = [type, options]
          instance_exec(name.to_s, options, &CODE.fetch(type))
        end

        # The raw associations code
        #
        CODE = {
          has_many: -> (entities, options) {
            klass, key, from = options.values_at(*[:class_name, :primary_key, :from])
            entity = entities.to_s.singularize

            class_eval <<-RUBY, __FILE__, __LINE__ + 1
              def #{entities}
                return @_#{entity} if instance_variable_defined?('@_#{entity}')
                @_#{entity} = #{parent}::#{klass}.where( clean_inherited_params( self.params, {
                    '#{key}' => self.id,
                    from:  #{from.inspect},
                } ) )
              end
            RUBY
          },

          has_one: -> (entity, options) {
            klass, key, from = options.values_at(*[:class_name, :primary_key, :from])

            class_eval <<-RUBY, __FILE__, __LINE__ + 1
              def #{entity}!
                return @_#{entity} if instance_variable_defined?('@_#{entity}')
                @_#{entity} = #{parent}::#{klass}.where( clean_inherited_params( self.params, {
                    '#{key}' => self.id,
                    from:  #{from.inspect},
                } ) ).first!
              end

              def #{entity}
                #{entity}!
              rescue Hawk::Error::NotFound
                nil
              end
            RUBY
          },

          monomorphic_belongs_to: -> (entity, options) {
            klass, key, params = options.values_at(*[:class_name, :primary_key, :params])
            params ||= {}
            ivar = "@_#{entity}".intern

            class_eval do
              define_method(entity) do
                return instance_variable_get(ivar) if instance_variable_defined?(ivar)
                return unless (id = self.attributes.fetch(key.to_s, nil))

                instance = self.class.model_class_for(klass).
                  find(id, clean_inherited_params( self.params, params ))

                instance_variable_set(ivar, instance)
              end
            end
          },

          polymorphic_belongs_to: -> (entity, options) {
            key = options.fetch(:as)

            class_eval <<-RUBY, __FILE__, __LINE__ + 1
              def #{entity}
                return @_#{entity} if instance_variable_defined?('@_#{entity}')
                @_#{entity} = begin
                  return unless self.#{key}
                  klass = self.class.model_class_for(self.#{entity}_type)
                  klass.find(self.#{key}, clean_inherited_params(self.params) )
                end
              end
            RUBY
          }

        }.freeze
      end
    end

  end
end

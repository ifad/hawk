# frozen_string_literal: true

module Hawk
  module Model
    ##
    # Provides ActiveRecord-like association methods for Hawk models.
    # Supports `has_many`, `has_one`, `belongs_to`, and polymorphic associations.
    #
    # @example Defining associations
    #   class Post < Hawk::Model::Base
    #     has_many :comments
    #     belongs_to :author
    #     has_one :image, as: :imageable
    #   end
    #
    #   class Comment < Hawk::Model::Base
    #     belongs_to :post
    #   end
    #
    module Association
      ##
      # Initializes the associations registry.
      #
      # @param base [Class] the model class
      def self.included(base)
        base.extend ClassMethods
        base.instance_eval { @_associations ||= {} }
      end

      ##
      # Preloads associations when a new entity is instantiated.
      #
      # @param attributes [Hash] model attributes
      # @param params [Hash] additional parameters
      def initialize(attributes = {}, params = {})
        super
        if attributes.present? && self.class.associations?
          preload_associations(attributes, params, self.class)
        end
      end

      private

      ##
      # Preloads associations from the given attributes.
      #
      # @param attributes [Hash] model attributes
      # @param _params [Hash] additional parameters (unused)
      # @param scope [Class] the model class
      def preload_associations(attributes, _params, scope)
        instance_exec(scope, attributes, &scope.preload_association)
      end

      ##
      # Adds an association object to the model instance.
      #
      # @param scope [Class] the model class
      # @param name [String, Symbol] the association name
      # @param repr [Hash, Array] the association representation
      def add_association_object(scope, name, repr)
        associations = scope.associations

        (type, options) = associations[name.to_sym]             ||
                          associations[name.pluralize.to_sym]   ||
                          associations[name.singularize.to_sym]
        if type
          target = scope.model_class_for(options.fetch(:class_name))
          result = target.instantiate_from(repr, params)

          if is_collection?(type)
            add_to_association_collection name, result
          else
            set_association_value name, result
          end
        else
          raise Hawk::Error, "Unhandled association: #{name}"
        end
      end

      ##
      # Checks if the association type is a collection.
      #
      # @param type [Symbol] the association type
      # @return [Boolean] true if the association is a collection
      def is_collection?(type)
        %i[polymorphic_belongs_to has_many].include? type
      end

      ##
      # Adds records to an association collection.
      #
      # @param name [String, Symbol] the association name
      # @param target [Array, Base] the records to add
      def add_to_association_collection(name, target)
        variable = "@_#{name}"
        instance_variable_set(variable, Collection.new) unless instance_variable_defined?(variable)
        collection = instance_variable_get(variable)
        target.respond_to?(:each) ? collection.concat(target) : collection.push(target)
      end

      ##
      # Sets the value of a single association.
      #
      # @param name [String, Symbol] the association name
      # @param target [Base] the associated record
      def set_association_value(name, target)
        instance_variable_set(:"@_#{name}", target)
      end

      ##
      # Cleans inherited params for associations.
      #
      # @param inherited [Hash] inherited parameters
      # @param opts [Hash] additional options
      # @return [Hash] cleaned parameters
      def clean_inherited_params(inherited, opts = {})
        rv = {}.deep_merge opts
        rv[:options] = inherited[:options] if inherited && inherited[:options]
        rv
      end

      ##
      # Class-level association definition and inheritance helpers.
      module ClassMethods
        ##
        # Propagates associations to subclasses on inheritance.
        #
        # @param subclass [Class] the subclass
        def inherited(subclass)
          super

          parent = self
          subclass.instance_eval do
            # Inherit associations
            @_associations ||= {}

            parent.associations.each do |name, (type, options)|
              _define_association(name, type, options.dup)
            end

            # Inherit association preloading behaviour
            preload_association(&parent.preload_association)
          end
        end

        ##
        # Defines how associations should be preloaded.
        #
        # The given block gets called when a new entity is instantiated, and
        # it gets passed the object attributes, the association's name, type
        # and options.
        #
        # @yield [scope, attributes, name, type, options] block to preload associations
        # @return [Proc] the preloading block
        #
        # @example Custom preloading
        #   class Foo < Hawk::Model::Base
        #     has_many :bars
        #
        #     preload_association do |attributes, name, type, options|
        #       if attributes.key?('links')
        #         links = attributes['links']
        #         if links.key?(name)
        #           return attributes.delete(links[name])
        #         end
        #       end
        #     end
        #   end
        def preload_association(&block)
          @preload_association = block if block
          @preload_association ||= lambda do |scope, attributes|
            if scope.associations?
              scope.associations.each_key do |name|
                attr = name.to_s
                next unless attributes.key?(attr)

                repr = attributes.delete(attr)
                add_association_object(scope, name, repr) if repr
              end
            end
          end
        end

        ##
        # Returns a copy of the associations registry.
        #
        # @return [Hash] the associations hash
        def associations
          @_associations.dup
        end

        ##
        # Checks whether associations are defined.
        #
        # @return [Boolean] true if associations are defined
        def associations?
          @_associations.present?
        end

        ##
        # Checks whether the given attribute is an association.
        #
        # @param attribute [String, Symbol] the attribute name
        # @return [Boolean] true if the attribute is an association
        def association?(attribute)
          @_associations.key?(attribute.to_sym)
        end

        ##
        # Defines a has_many association.
        #
        # @param entities [Symbol] the plural entity name
        # @param options [Hash] association options
        # @option options [String] :class_name the class name (defaults to entity name camelize)
        # @option options [String] :primary_key the foreign key (defaults to the current model name followed by <tt>_id</tt>)
        # @option options [String] :from the endpoint path to query
        # @option options [String] :as the polymorphic base name
        #
        # @example
        #   class Post < Hawk::Model::Base
        #     has_many :comments
        #   end
        #
        #   post = Post.find(1)
        #   post.comments.all # => [...]
        def has_many(entities, options = {})
          entity = entities.to_s.singularize
          klass  = options[:class_name] || entity.camelize
          key    = options[:primary_key] || [name.demodulize.underscore, :id].join('_')
          from   = options[:from]
          as     = options[:as]
          # TODO: params

          _define_association(entities, :has_many, class_name: klass, primary_key: key, from: from, as: as)
        end

        ##
        # Defines a has_one association.
        #
        # @param entity [Symbol] the singular entity name
        # @param options [Hash] association options
        # @option options [String] :class_name the class name (defaults to entity name camelize)
        # @option options [String] :primary_key the foreign key (defaults to the current model name followed by <tt>_id</tt>)
        # @option options [String] :from the endpoint path to query
        # @option options [Boolean] :nested whether to use nested routing
        # @option options [String] :as the polymorphic base name
        #
        # @example
        #   class Animal < Hawk::Model::Base
        #     has_one :favourite_food, class_name: 'Food'
        #   end
        #
        #   animal = Animal.find(1)
        #   animal.favourite_food # => #<Food ...>
        def has_one(entity, options = {})
          entity = entity.to_s
          klass  = options[:class_name] || entity.camelize
          key    = options[:primary_key] || [name.demodulize.underscore, :id].join('_')
          from   = options[:from]
          nested = options[:nested]
          as     = options[:as]
          # TODO: params

          _define_association(entity, :has_one, class_name: klass, primary_key: key, from: from, nested: nested, as: as)
        end

        ##
        # Defines a belongs_to association.
        #
        # @param entity [Symbol] the singular entity name
        # @param options [Hash] association options
        # @option options [String] :class_name the class name (defaults to entity name camelize)
        # @option options [String] :primary_key the foreign key (defaults to <tt>"#{entity}_id"</tt>)
        # @option options [Boolean] :polymorphic whether this is a polymorphic association
        #
        # @example
        #   class Comment < Hawk::Model::Base
        #     belongs_to :post
        #   end
        #
        #   comment = Comment.find(1)
        #   comment.post # => #<Post ...>
        def belongs_to(entity, options = {})
          if options[:polymorphic]
            polymorphic_belongs_to(entity, options)
          else
            monomorphic_belongs_to(entity, options)
          end
        end

        protected

        ##
        # Defines a monomorphic belongs_to association.
        #
        # @param entity [Symbol] the entity name
        # @param options [Hash] association options
        def monomorphic_belongs_to(entity, options)
          klass  = options[:class_name] || entity.to_s.camelize
          key    = options[:primary_key] || [entity, :id].join('_')
          params = options.fetch(:params, {})

          _define_association(entity, :monomorphic_belongs_to, class_name: klass, primary_key: key, params: params)
        end

        ##
        # Defines a polymorphic belongs_to association.
        #
        # @param entity [Symbol] the entity name
        # @param options [Hash] association options
        def polymorphic_belongs_to(entity, options)
          key = [options[:as] || entity, :id].join('_')
          # TODO: params

          _define_association(entity, :polymorphic_belongs_to, as: key)
        end

        private

        ##
        # Defines an association with the given name, type, and options.
        #
        # @param name [Symbol] the association name
        # @param type [Symbol] the association type
        # @param options [Hash] association options
        def _define_association(name, type, options)
          @_associations[name.to_sym] = [type, options]
          instance_exec(name.to_s, options, &CODE.fetch(type))
        end

        ##
        # The raw association code implementations.
        CODE = {
          has_many: lambda { |entities, options|
            klass, key, from, as = options.values_at(:class_name, :primary_key, :from, :as)

            conditions = if as.present?
                           "'#{as}_id' => self.id, '#{as}_type' => '#{name}'"
                         else
                           "'#{key}' => self.id"
                         end

            class_eval <<~RUBY, __FILE__, __LINE__ + 1
              def #{entities}
                return @_#{entities} if instance_variable_defined?('@_#{entities}')
                params = clean_inherited_params(self.params, #{conditions})

                @_#{entities} = self.class.model_class_for('#{klass}').where(params)
                #{"@_#{entities} = @_#{entities}.from(#{from.inspect})" if from}
                @_#{entities}
              end
            RUBY
          },

          has_one: lambda { |entity, options| # rubocop:disable Metrics/BlockLength
            klass, key, from, nested, as = options.values_at(:class_name, :primary_key, :from, :nested, :as)

            conditions = if as.present?
                           "'#{as}_id' => self.id, '#{as}_type' => '#{name}'"
                         else
                           "'#{key}' => self.id"
                         end

            class_eval <<~RUBY, __FILE__, __LINE__ + 1
              def #{entity}!
                return @_#{entity} if instance_variable_defined?('@_#{entity}')

                model = self.class.model_class_for('#{klass}')

                #{
                  if nested
                    %[
                      params = model.from('/' << path_for('#{entity}')).params
                      @_#{entity} = model.find_one(nil, params)
                    ]
                  else
                    %[
                      params = clean_inherited_params(self.params, #{conditions})
                      @_#{entity} = model.from(#{from.inspect}).where(params).first!
                    ]
                  end
                }

                @_#{entity}
              end

              def #{entity}
                #{entity}!
              rescue Hawk::Error::NotFound
                nil
              end
            RUBY
          },

          monomorphic_belongs_to: lambda { |entity, options|
            klass, key, params = options.values_at(:class_name, :primary_key, :params)
            params ||= {}
            ivar = :"@_#{entity}"

            class_eval do
              define_method(entity) do
                return instance_variable_get(ivar) if instance_variable_defined?(ivar)
                return unless (id = attributes.fetch(key.to_s, nil))

                instance = self.class.model_class_for(klass)
                               .find(id, clean_inherited_params(self.params, params))

                instance_variable_set(ivar, instance)
              end
            end
          },

          polymorphic_belongs_to: lambda { |entity, options|
            key = options.fetch(:as)

            class_eval <<~RUBY, __FILE__, __LINE__ + 1
              def #{entity}
                return @_#{entity} if instance_variable_defined?('@_#{entity}')
                @_#{entity} = begin
                  return unless self.#{key}
                  klass = self.class.model_class_for(self.#{entity}_type)
                  klass.find(self.#{key})
                end
              end
            RUBY
          }

        }.freeze
        private_constant :CODE
      end
    end
  end
end

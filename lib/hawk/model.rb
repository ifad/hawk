# frozen_string_literal: true

module Hawk
  ##
  # Namespace for all Model-related functionalities. This module contains
  # the core components for defining API client models, including schema
  # definitions, associations, querying, and connection management.
  #
  # @see Hawk::Model::Base
  module Model
    autoload :Base,           'hawk/model/base'
    autoload :Schema,         'hawk/model/schema'
    autoload :Connection,     'hawk/model/connection'
    autoload :Finder,         'hawk/model/finder'
    autoload :Querying,       'hawk/model/querying'
    autoload :Proxy,          'hawk/model/proxy'
    autoload :Association,    'hawk/model/association'
    autoload :Collection,     'hawk/model/collection'
    autoload :Pagination,     'hawk/model/pagination'
    autoload :Configurator,   'hawk/model/configurator'
    autoload :Lookup,         'hawk/model/lookup'
    autoload :Scoping,        'hawk/model/scoping'
    autoload :Active,         'hawk/model/active'
  end
end

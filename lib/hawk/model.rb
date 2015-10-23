module Hawk

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

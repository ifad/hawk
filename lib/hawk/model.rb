module Hawk

  module Model
    autoload :Base,        'hawk/model/base'
    autoload :Schema,      'hawk/model/schema'
    autoload :Connection,  'hawk/model/connection'
    autoload :Finder,      'hawk/model/finder'
    autoload :Querying,    'hawk/model/querying'
    autoload :Proxy,       'hawk/model/proxy'
    autoload :Association, 'hawk/model/association'
  end

end

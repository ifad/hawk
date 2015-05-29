require 'hawk/version'

##
# Hawk entry point.
#
module Hawk

  autoload :Error, 'hawk/error'
  autoload :HTTP,  'hawk/http'
  autoload :Model, 'hawk/model'

end

require 'hawk/polyfills' # DIH

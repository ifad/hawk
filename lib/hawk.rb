##
# Hawk entry point.
#
#

require 'active_support/core_ext/array/wrap'
require 'active_support/core_ext/hash/deep_merge'
require 'active_support/core_ext/module/introspection'
require 'active_support/core_ext/string/inflections'

require 'hawk/version'

require 'hawk/error'
require 'hawk/http'
require 'hawk/model'

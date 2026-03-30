# frozen_string_literal: true

module Hawk
  class HTTP
    module CacheAdapters
      autoload :DalliAdapter, 'hawk/http/cache_adapters/dalli_adapter'
      autoload :RedisAdapter, 'hawk/http/cache_adapters/redis_adapter'
    end
  end
end

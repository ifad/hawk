# frozen_string_literal: true

module Hawk
  # Namespace to all rake-related functionalities.
  module Rake
    autoload :Utils,       'hawk/rake/utils.rb'
    autoload :DefaultTask, 'hawk/rake/default_task.rb'
  end
end

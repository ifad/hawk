# frozen_string_literal: true

# Bundler
require 'bundler/setup'
require 'bundler/gem_tasks'

# RSpec
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new

# Appraisal
require 'appraisal/task'
Appraisal::Task.new

# Yard
require 'yard'
YARD::Rake::YardocTask.new

# Our default rake task
require 'hawk/rake'
Hawk::Rake::DefaultTask.new

# Thanks for reading.

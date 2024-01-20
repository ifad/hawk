# frozen_string_literal: true

require File.expand_path('lib/hawk/version', __dir__)

Gem::Specification.new do |spec|
  spec.name          = 'hawk'
  spec.version       = Hawk::VERSION
  spec.authors       = ['Marcello Barnaba']
  spec.email         = ['vjt@openssl.it']

  spec.summary       = 'API Client Framework'
  spec.homepage      = 'https://github.com/ifad/hawk'
  spec.license       = 'MIT'

  spec.files         = Dir.glob('{LICENSE,README.md,lib/**/*.rb}', File::FNM_DOTMATCH)
  spec.require_paths = ['lib']

  spec.metadata = {
    'bug_tracker_uri' => 'https://github.com/ifad/hawk/issues',
    'homepage_uri' => 'https://github.com/ifad/hawk',
    'source_code_uri' => 'https://github.com/ifad/hawk',
    'rubygems_mfa_required' => 'true'
  }

  spec.required_ruby_version = '>= 3.0'

  spec.add_dependency 'activemodel', '>= 7.0'
  spec.add_dependency 'dalli'
  spec.add_dependency 'ethon', '>= 0.16.0'
  spec.add_dependency 'multi_json'
  spec.add_dependency 'typhoeus'
end

# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hawk/version'

Gem::Specification.new do |spec|
  spec.name          = "hawk"
  spec.version       = Hawk::VERSION
  spec.authors       = ["Marcello Barnaba"]
  spec.email         = ["vjt@openssl.it"]

  spec.summary       = %q{API Client Framework}
  spec.homepage      = "https://github.com/ifad/hawk"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'typhoeus'
  spec.add_dependency 'ethon', '>= 0.7.4'
  spec.add_dependency 'multi_json'
  spec.add_dependency 'dalli'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'byebug'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'webmock'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'appraisal'
end

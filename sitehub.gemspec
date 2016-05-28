# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sitehub/version'

Gem::Specification.new do |spec|
  spec.name          = 'sitehub'
  spec.version       = SiteHub::VERSION
  spec.authors       = ['Ladtech']
  spec.email         = ['team@lad-tech.com']
  spec.summary       = 'A/B testing enabled HTTP proxy'
  spec.description   = 'A/B testing enabled HTTP proxy'
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(spec)/*.rb})
  spec.require_paths = ['lib']

  spec.add_dependency 'rack'
  spec.add_dependency 'uuid'
  spec.add_dependency 'em-http-request'
  spec.add_dependency 'rack-ssl-enforcer'
  spec.add_dependency 'rack-fiber_pool'
  spec.add_dependency 'faraday'
  spec.add_dependency 'em-synchrony'
  spec.add_dependency 'thin'

  spec.add_development_dependency 'bundler', '~> 1.5'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 3.2.0'
  spec.add_development_dependency 'webmock'
  spec.add_development_dependency 'rack-test'
  spec.add_development_dependency 'geminabox'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'memory_profiler'
  spec.add_development_dependency 'codeclimate-test-reporter'
  spec.add_development_dependency 'reek'

  spec.add_development_dependency 'ruby-prof'
end

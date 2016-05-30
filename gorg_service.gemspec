# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'gorg_service/version'

Gem::Specification.new do |spec|
  spec.name          = "gorg_service"
  spec.version       = GorgService::VERSION
  spec.authors       = ["Alexandre Narbonne"]
  spec.email         = ["alexandre.narbonne@gadz.org"]

  spec.summary       = "Standard RabbitMQ bot used in Gadz.org SOA"
  spec.homepage      = "https://github.com/Zooip/gorg_service"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'bunny', '~> 2.2', '>= 2.2.2'
  spec.add_dependency 'json-schema', '~> 2.6'

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "codeclimate-test-reporter", "~> 3.0"
  spec.add_development_dependency 'bogus', '~> 0.1.6'
  spec.add_development_dependency 'bunny-mock', '~> 1.4'
  spec.add_development_dependency 'byebug', '~> 9.0'
end

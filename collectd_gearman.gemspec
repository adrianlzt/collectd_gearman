# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'collectd_gearman/version'

Gem::Specification.new do |spec|
  spec.name          = "collectd_gearman"
  spec.version       = CollectdGearman::VERSION
  spec.authors       = ["Adrian Lopez"]
  spec.email         = ["adrianlzt@gmail.com"]
  spec.summary       = %q{Convert collectd notifications in passive checks sent via send_gearman}
  spec.description   = %q{Executable to be used with NotificationExec in collectd. It will send several passive checks, from specific to general plugin-type.}
  spec.homepage      = "https://github.com/adrianlzt/collectd_gearman"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"

  spec.add_runtime_dependency 'yaml'
  spec.add_runtime_dependency 'optparse'
  spec.add_runtime_dependency 'ostruct'
end
